import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';

import '../../Provider/product_provider.dart';
import '../../currency.dart';

class StockList extends StatefulWidget {
  const StockList({super.key, required this.isFromReport});

  final bool isFromReport;

  @override
  StockListState createState() => StockListState();
}

class StockListState extends State<StockList> {
  String productSearch = '';
  bool _isRefreshing = false;
  String selectedFilter = 'All';
  String selectedExpireFilter = '7 Days';

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    ref.refresh(productProvider);
    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  final _horizontalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(productProvider);
      return providerData.when(
        data: (product) {
          double totalStockValue = 0;
          List<ProductModel> showableProducts = [];
          DateTime now = DateTime.now();

          for (var element in product) {
            bool matchesSearch = element.productName!.toLowerCase().contains(productSearch.toLowerCase().trim());
            bool matchesFilter = selectedFilter == 'All' || (selectedFilter == 'Low Stock' && (element.productStock ?? 0) <= (element.alertQty ?? 0));

            // Expire ফিল্টারিং
            bool matchesExpireFilter = true;
            if (selectedFilter == 'Expire') {
              DateTime? expiryDate = DateTime.tryParse(element.expireDate ?? '');
              if (expiryDate != null) {
                int daysLeft = expiryDate.difference(now).inDays;
                switch (selectedExpireFilter) {
                  case '7 Days':
                    matchesExpireFilter = daysLeft <= 7 && daysLeft > 0;
                    break;
                  case '10 Days':
                    matchesExpireFilter = daysLeft <= 10 && daysLeft > 0;
                    break;
                  case '15 Days':
                    matchesExpireFilter = daysLeft <= 15 && daysLeft > 0;
                    break;
                  case '30 Days':
                    matchesExpireFilter = daysLeft <= 30 && daysLeft > 0;
                    break;
                  case '50 Days':
                    matchesExpireFilter = daysLeft <= 50 && daysLeft > 0;
                    break;
                  case 'Expired':
                    matchesExpireFilter = daysLeft <= 0;
                    break;
                }
              } else {
                matchesExpireFilter = false;
              }
            }

            if (selectedFilter == 'Expire') {
              if (matchesSearch && matchesExpireFilter) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) * (element.productStock ?? 0);
              }
            } else if (selectedFilter == 'Low Stock') {
              if (matchesSearch && matchesFilter) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) * (element.productStock ?? 0);
              }
            } else {
              if (matchesSearch) {
                showableProducts.add(element);
                totalStockValue += (element.productPurchasePrice ?? 0) * (element.productStock ?? 0);
              }
            }
          }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                lang.S.of(context).stockList,
              ),
              // centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: updateBorderColor),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    isDense: true,
                    value: selectedFilter,
                    icon: const Icon(IconlyLight.arrow_down_2, color: Colors.black, size: 14),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        // selectedExpireFilter = null; // Expire ফিল্টার রিসেট
                      });
                    },
                    items: <String>['All', 'Low Stock', 'Expire'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                  ),
                ),
              ],
              toolbarHeight: 100,
              bottom: PreferredSize(
                preferredSize: const Size(double.infinity, 40),
                child: Column(
                  children: [
                    Container(
                      color: updateBorderColor.withValues(alpha: 0.5),
                      width: double.infinity,
                      height: 1,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Flexible(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFormField(
                              // controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  productSearch = value;
                                });
                              },
                              decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: updateBorderColor, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(
                                      FeatherIcons.search,
                                      color: kNeutralColor,
                                    ),
                                  ),
                                  hintText: lang.S.of(context).searchH,
                                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: kNeutralColor,
                                      )),
                            ),
                          ),
                        ),
                        if (selectedFilter == 'Expire')
                          Flexible(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Container(
                                alignment: Alignment.center,
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: updateBorderColor),
                                ),
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  isDense: true,
                                  value: selectedExpireFilter,
                                  hint: Text("Select Days", style: theme.textTheme.bodyMedium),
                                  icon: const Icon(IconlyLight.arrow_down_2, color: Colors.black, size: 14),
                                  underline: Container(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedExpireFilter = newValue!;
                                    });
                                  },
                                  items: <String>['7 Days', '15 Days', '30 Days', '60 Days', 'Expired'].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: theme.textTheme.bodyMedium),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: RefreshIndicator(
                onRefresh: () => refreshData(ref),
                child: Column(
                  children: [
                    showableProducts.isNotEmpty
                        ? LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              final kWidth = constraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScroll,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: kWidth),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerTheme: const DividerThemeData(color: Colors.transparent)),
                                    child: DataTable(
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(
                                          width: 1,
                                          color: updateBorderColor,
                                        ),
                                      ),
                                      dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                      headingRowColor: WidgetStateProperty.all(const Color(0xffFEF0F1)),
                                      showBottomBorder: false,
                                      dividerThickness: 0.0,
                                      headingTextStyle: theme.textTheme.titleSmall,
                                      dataTextStyle: theme.textTheme.bodyMedium,
                                      columnSpacing: 20.0,
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 40,
                                      // headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xffFEF0F1)),
                                      columns: [
                                        DataColumn(label: Text(lang.S.of(context).product)),
                                        DataColumn(label: Text(lang.S.of(context).cost)),
                                        DataColumn(label: Text(lang.S.of(context).qty)),
                                        DataColumn(label: Text(lang.S.of(context).sale)),
                                      ],
                                      rows: showableProducts.map((product) {
                                        bool isLowStock = (product.productStock ?? 0) <= (product.alertQty ?? 0);
                                        return DataRow(cells: [
                                          DataCell(
                                            (product.brand?.brandName != null)
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        constraints: const BoxConstraints(minWidth: 30, maxWidth: 250),
                                                        child: Text(
                                                          product.productName ?? 'N/A',
                                                          style: theme.textTheme.bodyMedium?.copyWith(),
                                                          textAlign: TextAlign.start,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${product.brand?.brandName}',
                                                        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xff999999), fontSize: 13),
                                                        textAlign: TextAlign.start,
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    product.productName ?? 'N?A',
                                                    style: theme.textTheme.bodyMedium,
                                                    textAlign: TextAlign.start,
                                                  ),
                                          ),
                                          DataCell(Text('$currency${product.productPurchasePrice?.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(color: isLowStock ? Colors.red : Colors.black))),
                                          DataCell(
                                            Text(
                                              product.productStock.toString(),
                                              style: TextStyle(color: isLowStock ? Colors.red : Colors.black),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '$currency${product.productSalePrice?.toStringAsFixed(2)}',
                                              style: TextStyle(color: isLowStock ? Colors.red : Colors.black),
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : EmptyWidget(
                            message: TextSpan(text: lang.S.of(context).noProductFound),
                          ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              color: const Color(0xffFEF0F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.S.of(context).stockValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$currency${totalStockValue.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
        error: (e, stack) => Center(child: Text("Error: $e")),
        loading: () => const Center(child: CircularProgressIndicator()),
      );
    });
  }
}
