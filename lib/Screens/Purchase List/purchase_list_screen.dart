import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/Screens/Purchase/add_and_edit_purchase.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../PDF Invoice/purchase_invoice_pdf.dart';
import '../../Provider/add_to_cart_purchase.dart';
import '../../core/theme/_app_colors.dart';
import '../../currency.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Home/home.dart';
import '../invoice return/invoice_return_screen.dart';
import '../invoice_details/purchase_invoice_details.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  PurchaseReportState createState() => PurchaseReportState();
}

class PurchaseReportState extends State<PurchaseListScreen> {
  bool _isRefreshing = false;
  TextEditingController searchController = TextEditingController();

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    // Refreshing the base provider will automatically update the filtered provider
    ref.refresh(purchaseTransactionProvider);

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
    return WillPopScope(
      onWillPop: () async {
        return await const Home().launch(context, isNewTask: true);
      },
      child: GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(lang.S.of(context).purchaseList),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            // Watch the providers we set up in the transactions_provider.dart
            final providerData = ref.watch(filteredPurchaseProvider);
            final searchString = ref.watch(purchaseSearchProvider);

            final printerData = ref.watch(thermalPrinterProvider);
            final businessSetting = ref.watch(businessSettingProvider);
            final businessInfoData = ref.watch(businessInfoProvider);

            return Column(
              children: [
                /// --- SEARCH BAR UI ---
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
                        // Updates the search state in Riverpod to trigger the filter logic
                        ref.read(purchaseSearchProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search supplier or invoice...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: searchString.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  ref.read(purchaseSearchProvider.notifier).state = '';
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
                  child: RefreshIndicator.adaptive(
                    onRefresh: () => refreshData(ref),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: providerData.when(
                        data: (purchaseTransactions) {
                          if (purchaseTransactions.isEmpty) {
                            return Center(
                              child: EmptyWidget(
                                message: TextSpan(
                                  text: searchString.isEmpty 
                                      ? lang.S.of(context).addAPurchase 
                                      : "No transactions found",
                                ),
                              ),
                            );
                          }
                          return businessInfoData.when(
                            data: (details) {
                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: purchaseTransactions.length,
                                itemBuilder: (context, index) {
                                  final purchase = purchaseTransactions[index];
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          PurchaseInvoiceDetails(
                                            businessInfo: details,
                                            transitionModel: purchase,
                                          ).launch(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          width: context.width(),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      purchase.party?.name ?? '',
                                                      style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '#${purchase.invoiceNumber}',
                                                    style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                            color: purchase.dueAmount! <= 0 ? const Color(0xff0dbf7d).withOpacity(0.1) : const Color(0xFFED1A3B).withOpacity(0.1),
                                                            borderRadius: const BorderRadius.all(Radius.circular(2))),
                                                        child: Text(
                                                          purchase.dueAmount! <= 0 ? lang.S.of(context).paid : lang.S.of(context).unPaid,
                                                          style: TextStyle(color: purchase.dueAmount! <= 0 ? const Color(0xff0dbf7d) : const Color(0xFFED1A3B)),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: purchase.purchaseReturns?.isNotEmpty ?? false,
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(left: 8, right: 8),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: const BorderRadius.all(Radius.circular(2))),
                                                            child: Text(
                                                              lang.S.of(context).returned,
                                                              style: const TextStyle(color: Colors.orange),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    DateFormat.yMMMd().format(DateTime.parse(purchase.purchaseDate ?? DateTime.now().toString())),
                                                    style: const TextStyle(color: DAppColors.kSecondary),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${lang.S.of(context).total} : $currency ${purchase.totalAmount.toString()}',
                                                    style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: DAppColors.kSecondary),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (purchase.dueAmount!.toInt() != 0)
                                                    Text(
                                                      '${lang.S.of(context).paid} : $currency ${purchase.totalAmount!.toDouble() - purchase.dueAmount!.toDouble()}',
                                                      style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: DAppColors.kSecondary),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  if (purchase.dueAmount!.toInt() == 0)
                                                    Flexible(
                                                      child: Text(
                                                        '${lang.S.of(context).paid} : $currency ${purchase.totalAmount!.toDouble() - purchase.dueAmount!.toDouble()}',
                                                        style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                  if (purchase.dueAmount!.toInt() != 0)
                                                    Text(
                                                      '${lang.S.of(context).due}: $currency ${purchase.dueAmount.toString()}',
                                                      style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                                                    ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                          padding: EdgeInsets.zero,
                                                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                          onPressed: () async {
                                                            PrintPurchaseTransactionModel model = PrintPurchaseTransactionModel(purchaseTransitionModel: purchase, personalInformationModel: details);
                                                            await printerData.printPurchaseThermalInvoiceNow(
                                                              transaction: model,
                                                              productList: model.purchaseTransitionModel!.details,
                                                              context: context,
                                                            );
                                                          },
                                                          icon: const Icon(FeatherIcons.printer, color: Colors.grey)),
                                                      const SizedBox(width: 6),
                                                      businessSetting.when(
                                                        data: (bussiness) {
                                                          return Row(
                                                            children: [
                                                              IconButton(
                                                                  padding: EdgeInsets.zero,
                                                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                                  onPressed: () => PurchaseInvoicePDF.generatePurchaseDocument(purchase, details, context, bussiness),
                                                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.grey)),
                                                              IconButton(
                                                                padding: EdgeInsets.zero,
                                                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                                onPressed: () => PurchaseInvoicePDF.generatePurchaseDocument(purchase, details, context, bussiness, isShare: true),
                                                                icon: const Icon(Icons.share_outlined, color: Colors.grey),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                        error: (e, stack) => const SizedBox(),
                                                        loading: () => const SizedBox(),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Visibility(
                                                        visible: !(purchase.purchaseReturns?.isNotEmpty ?? false),
                                                        child: IconButton(
                                                            padding: EdgeInsets.zero,
                                                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                            onPressed: () async {
                                                              ref.refresh(cartNotifierPurchaseNew);
                                                              AddAndUpdatePurchaseScreen(transitionModel: purchase, customerModel: null).launch(context);
                                                            },
                                                            icon: const Icon(FeatherIcons.edit, color: Colors.grey)),
                                                      ),
                                                      PopupMenuButton(
                                                        offset: const Offset(0, 30),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                                                        itemBuilder: (BuildContext bc) => [
                                                          PopupMenuItem(
                                                            child: GestureDetector(
                                                              onTap: () async {
                                                                await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(builder: (context) => InvoiceReturnScreen(purchaseTransaction: purchase)),
                                                                );
                                                                Navigator.pop(bc);
                                                              },
                                                              child: const Row(
                                                                children: [
                                                                  Icon(Icons.keyboard_return_outlined, color: kGreyTextColor),
                                                                  SizedBox(width: 10.0),
                                                                  Text('Purchase return', style: TextStyle(color: kGreyTextColor)),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        child: const Icon(FeatherIcons.moreVertical, color: kGreyTextColor),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 0)
                                    ],
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
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}