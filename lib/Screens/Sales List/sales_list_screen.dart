import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/sales_transaction_widget.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Home/home.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  _SalesListScreenState createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  bool _isRefreshing = false;
  TextEditingController searchController = TextEditingController();

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    ref.refresh(salesTransactionProvider);
    ref.refresh(businessInfoProvider);
    ref.refresh(getExpireDateProvider(ref));
    ref.refresh(thermalPrinterProvider);

    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await const Home().launch(context, isNewTask: true);
      },
      child: GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(lang.S.of(context).saleList),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            // Watch the filtered provider and search string
            final providerData = ref.watch(filteredSalesProvider);
            final searchString = ref.watch(salesSearchProvider);
            final profile = ref.watch(businessInfoProvider);

            return Column(
              children: [
                // --- SEARCH BAR UI ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        ref.read(salesSearchProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search customer or invoice...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: searchString.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  ref.read(salesSearchProvider.notifier).state = '';
                                },
                                child: const Icon(Icons.cancel, color: kMainColor),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // --- LIST VIEW ---
                Expanded(
                  child: RefreshIndicator.adaptive(
                    onRefresh: () => refreshData(ref),
                    child: providerData.when(
                      data: (transaction) {
                        if (transaction.isEmpty) {
                          return Center(
                            child: EmptyWidget(
                              message: TextSpan(
                                text: searchString.isEmpty ? lang.S.of(context).addSale : "No sales found",
                              ),
                            ),
                          );
                        }
                        return profile.when(
                          data: (shopDetails) {
                            return ListView.builder(
                              itemCount: transaction.length,
                              padding: const EdgeInsets.only(bottom: 20),
                              itemBuilder: (context, index) {
                                return salesTransactionWidget(
                                  context: context,
                                  ref: ref,
                                  businessInfo: shopDetails,
                                  sale: transaction[index],
                                  advancePermission: true,
                                );
                              },
                            );
                          },
                          error: (e, stack) => Text(e.toString()),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        );
                      },
                      error: (e, stack) => Text(e.toString()),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}