import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/invoice_constant.dart';

import '../../../Provider/product_provider.dart';
import '../../../currency.dart';

class ExpiredList extends StatefulWidget {
  const ExpiredList({super.key});

  @override
  ExpiredListState createState() => ExpiredListState();
}

class ExpiredListState extends State<ExpiredList> {
  String productSearch = '';
  bool _isRefreshing = false;
  String selectedFilter = 'All';

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    ref.refresh(productProvider);

    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  List<ProductModel> filterProducts(List<ProductModel> products) {
    DateTime now = DateTime.now();
    return products.where((product) {
      DateTime? expireDate = product.expireDate != null ? DateTime.parse(product.expireDate.toString()) : null;
      if (selectedFilter == 'All') {
        return true;
      } else if (selectedFilter == 'Expired') {
        return expireDate != null && expireDate.isBefore(now);
      } else {
        int daysUntilExpiration = expireDate != null ? expireDate.difference(now).inDays : -1;
        if (selectedFilter == '7 days') {
          return daysUntilExpiration >= 0 && daysUntilExpiration <= 7;
        } else if (selectedFilter == '15 days') {
          return daysUntilExpiration > 7 && daysUntilExpiration <= 15;
        } else if (selectedFilter == '30 days') {
          return daysUntilExpiration > 15 && daysUntilExpiration <= 30;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final _lang = lang.S.of(context);
    final _theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(productProvider);
      return providerData.when(
        data: (product) {
          double totalParPrice = 0;
          List<ProductModel> filteredProducts = filterProducts(product);
          List<ProductModel> showableProducts = [];
          for (var element in filteredProducts) {
            if (element.productName!.toLowerCase().contains(productSearch.toLowerCase().trim())) {
              showableProducts.add(element);
              totalParPrice += (element.productPurchasePrice ?? 0) * (element.productStock ?? 0);
            }
          }
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                _lang.expiredList,
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: kBorderColorTextField,
                    ),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    isDense: true,
                    value: selectedFilter,
                    icon: const Icon(
                      IconlyLight.arrow_down_2,
                      color: Colors.black,
                      size: 14,
                    ),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    },
                    items: <String>['All', 'Expired', '7 days', '15 days', '30 days'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => refreshData(ref),
              child: showableProducts.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shrinkWrap: true,
                      itemCount: showableProducts.length,
                      itemBuilder: (_, i) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    showableProducts[i].productName.toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    text: '${lang.S.of(context).sale}: ',
                                    style: _theme.textTheme.bodyMedium?.copyWith(
                                      color: kGreyTextColor,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$currency${showableProducts[i].productSalePrice.toString() ?? 'N/A'}',
                                        style: _theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: '${lang.S.of(context).code}: ',
                                    style: _theme.textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: showableProducts[i].productCode ?? 'N/A',
                                        style: _theme.textTheme.bodyMedium,
                                      )
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      text: '${lang.S.of(context).purchase}: ',
                                      style: _theme.textTheme.bodyMedium?.copyWith(
                                        color: kGreyTextColor,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$currency${showableProducts[i].productPurchasePrice ?? '0'}',
                                          style: _theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    text: '${lang.S.of(context).stock}: ',
                                    style: _theme.textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: showableProducts[i].productStock.toString(),
                                        style: _theme.textTheme.bodyMedium,
                                      )
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: RichText(
                                    maxLines: 1,
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.visible,
                                    text: TextSpan(
                                      text: showableProducts[i].expireDate != null
                                          ? getExpirationStatus(
                                              DateTime.parse(
                                                showableProducts[i].expireDate.toString(),
                                              ),
                                            )
                                          : 'N/A',
                                      style: TextStyle(
                                        color: showableProducts[i].expireDate != null
                                            ? _getExpirationColor(
                                                DateTime.parse(
                                                  showableProducts[i].expireDate.toString(),
                                                ),
                                              )
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const Divider(
                              thickness: 1.0,
                              color: kBorderColorTextField,
                            )
                          ],
                        );
                      })
                  : Center(
                      child: Text(
                        _lang.listIsEmpty,
                        style: _theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            bottomNavigationBar: Container(
              color: const Color(0xffFEF0F1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.S.of(context).stockValue,
                      style: _theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currency${totalParPrice.toInt().toString()}',
                      overflow: TextOverflow.ellipsis,
                      style: _theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        error: (e, stack) {
          return Text(e.toString());
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
      );
    });
  }
}

Color _getExpirationColor(DateTime expireDate) {
  final DateTime now = DateTime.now();
  final Duration difference = expireDate.difference(now);

  if (difference.isNegative || difference.inDays <= 30) {
    return Colors.red;
  } else {
    return Colors.black;
  }
}

String getExpirationStatus(DateTime date) {
  final DateTime now = DateTime.now();
  final Duration difference = date.difference(now);

  if (difference.isNegative) {
    return 'Expired';
  } else if (difference.inDays <= 7) {
    return 'Exp. in ${difference.inDays} days';
  } else if (difference.inDays <= 15) {
    return 'Exp. in ${difference.inDays} days';
  } else if (difference.inDays <= 30) {
    return 'Exp. in ${difference.inDays} days';
  } else {
    return 'Exp. on ${date.toLocal().toString().split(' ')[0]}';
  }
}
