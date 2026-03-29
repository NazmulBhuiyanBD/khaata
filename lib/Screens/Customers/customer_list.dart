import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/Customers/Provider/customer_provider.dart';
import 'package:mobile_pos/Screens/Customers/add_customer.dart';
import 'package:mobile_pos/Screens/Customers/customer_details.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../currency.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  late Color color;
  bool _isRefreshing = false;
  
  // Controller to manage the UI text
  TextEditingController searchController = TextEditingController();

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    ref.refresh(partiesProvider);
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
    final _theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, __) {
        // Watch the filtered provider and the search string
        final providerData = ref.watch(filteredPartiesProvider);
        final searchString = ref.watch(partySearchProvider);
        final businessInfo = ref.watch(businessInfoProvider);

        return businessInfo.when(data: (details) {
          return GlobalPopup(
            child: Scaffold(
              backgroundColor: kWhite,
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(lang.S.of(context).partyList),
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.black),
                elevation: 0.0,
              ),
              body: Column(
                children: [
                  /// --- SEARCH BAR ---
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
                          // Update Riverpod state instantly
                          ref.read(partySearchProvider.notifier).state = value;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: searchString.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    searchController.clear();
                                    ref.read(partySearchProvider.notifier).state = '';
                                  },
                                  child: const Icon(Icons.cancel, color: kMainColor),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  /// --- LIST VIEW ---
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => refreshData(ref),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: providerData.when(
                          data: (customer) {
                            return customer.isNotEmpty
                                ? ListView.builder(
                                    itemCount: customer.length,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemBuilder: (_, index) {
                                      // Type color logic
                                      customer[index].type == 'Retailer' ? color = const Color(0xFF56da87) : Colors.white;
                                      customer[index].type == 'Wholesaler' ? color = const Color(0xFF25a9e0) : Colors.white;
                                      customer[index].type == 'Dealer' ? color = const Color(0xFFff5f00) : Colors.white;
                                      customer[index].type == 'Supplier' ? color = const Color(0xFFA569BD) : Colors.white;

                                      return ListTile(
                                        visualDensity: const VisualDensity(vertical: -2),
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () {
                                          CustomerDetails(party: customer[index]).launch(context);
                                        },
                                        leading: customer[index].image != null
                                            ? Container(
                                                height: 40,
                                                width: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: DAppColors.kBorder, width: 0.3),
                                                  image: DecorationImage(
                                                      image: NetworkImage('${APIConfig.domain}${customer[index].image ?? ''}'),
                                                      fit: BoxFit.cover),
                                                ),
                                              )
                                            : CircleAvatarWidget(name: customer[index].name),
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                customer[index].name ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: _theme.textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black,
                                                  fontSize: 16.0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$currency${customer[index].due}',
                                              style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16.0),
                                            ),
                                          ],
                                        ),
                                        subtitle: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                customer[index].type ?? '',
                                                style: _theme.textTheme.bodyMedium?.copyWith(color: color, fontSize: 14.0),
                                              ),
                                            ),
                                            Text(
                                              customer[index].due != null && customer[index].due != 0 ? lang.S.of(context).due : 'No Due',
                                              style: _theme.textTheme.bodyMedium?.copyWith(
                                                color: customer[index].due != null && customer[index].due != 0 ? const Color(0xFFff5f00) : DAppColors.kSecondary,
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(IconlyLight.arrow_right_2, size: 18),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 50),
                                      child: EmptyWidget(
                                        message: TextSpan(text: searchString.isEmpty ? "No Parties Found" : "No results for '$searchString'"),
                                      ),
                                    ),
                                  );
                          },
                          error: (e, stack) => Text(e.toString()),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ElevatedButton.icon(
                  style: OutlinedButton.styleFrom(
                    maximumSize: const Size(double.infinity, 48),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddParty()));
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    lang.S.of(context).addCustomer,
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      color: _theme.colorScheme.primaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }, error: (e, stack) => Text(e.toString()), loading: () => const Center(child: CircularProgressIndicator()));
      },
    );
  }
}