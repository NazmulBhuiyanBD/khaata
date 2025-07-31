import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/Screens/Loss_Profit/single_loss_profit_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../Provider/profile_provider.dart';
import '../../../constant.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/returned_tag_widget.dart';
import '../../currency.dart';
import '../../model/sale_transaction_model.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../Home/home.dart';

class LossProfitScreen extends StatefulWidget {
  const LossProfitScreen({super.key, this.fromReport});

  final bool? fromReport;

  @override
  // ignore: library_private_types_in_public_api
  _LossProfitScreenState createState() => _LossProfitScreenState();
}

class _LossProfitScreenState extends State<LossProfitScreen> {
  TextEditingController fromDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(DateTime(2021)));
  TextEditingController toDateTextEditingController = TextEditingController(text: DateFormat.yMMMd().format(DateTime.now()));
  DateTime fromDate = DateTime(2021);
  DateTime toDate = DateTime.now();

  num calculateTotalProductQtyNow({required SalesTransactionModel sales}) {
    num totalQty = 0;
    for (var element in sales.salesDetails!) {
      totalQty += element.quantities ?? 0;
    }
    return totalQty;
  }

  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(salesTransactionProvider);

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
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
            backgroundColor: Colors.white,
            title: Text(
              (widget.fromReport ?? false) ? 'Loss/Profit Report' : lang.S.of(context).lp,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            final providerData = ref.watch(salesTransactionProvider);
            final printerData = ref.watch(thermalPrinterProvider);
            final personalData = ref.watch(businessInfoProvider);

            return RefreshIndicator(
              onRefresh: () => refreshData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20, bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              textFieldType: TextFieldType.NAME,
                              readOnly: true,
                              controller: fromDateTextEditingController,
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).fromDate,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () async {
                                    final DateTime? picked = await showDatePicker(
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2015, 8),
                                      lastDate: DateTime(2101),
                                      context: context,
                                    );
                                    setState(() {
                                      fromDateTextEditingController.text = DateFormat.yMMMd().format(picked ?? DateTime.now());
                                      fromDate = picked!;
                                    });
                                  },
                                  icon: const Icon(FeatherIcons.calendar),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              textFieldType: TextFieldType.NAME,
                              readOnly: true,
                              controller: toDateTextEditingController,
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).toDate,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () async {
                                    final DateTime? picked = await showDatePicker(
                                      initialDate: toDate,
                                      firstDate: DateTime(2015, 8),
                                      lastDate: DateTime(2101),
                                      context: context,
                                    );

                                    setState(() {
                                      toDateTextEditingController.text = DateFormat.yMMMd().format(picked ?? DateTime.now());
                                      picked!.isToday ? toDate = DateTime.now() : toDate = picked;
                                    });
                                  },
                                  icon: const Icon(FeatherIcons.calendar),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    providerData.when(data: (transaction) {
                      double totalProfit = 0;
                      double totalLoss = 0;
                      for (var element in transaction) {
                        if ((fromDate.isBefore(DateTime.parse(element.saleDate ?? '')) || DateTime.parse(element.saleDate ?? '').isAtSameMomentAs(fromDate)) && (toDate.isAfter(DateTime.parse(element.saleDate ?? '')) || DateTime.parse(element.saleDate ?? '').isAtSameMomentAs(toDate))) {
                          (element.detailsSumLossProfit ?? 0).isNegative ? totalLoss = totalLoss + (element.detailsSumLossProfit ?? 0).abs() : totalProfit = totalProfit + (element.detailsSumLossProfit ?? 0);
                        }
                      }

                      return transaction.isNotEmpty
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: kMainColor.withOpacity(0.1), border: Border.all(width: 1, color: kMainColor), borderRadius: const BorderRadius.all(Radius.circular(15))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$currency ${totalProfit.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              lang.S.of(context).profit,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 1,
                                          height: 60,
                                          color: kMainColor,
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$currency ${totalLoss.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              lang.S.of(context).loss,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transaction.length,
                                  itemBuilder: (context, index) {
                                    return (fromDate.isBefore(DateTime.parse(transaction[index].saleDate ?? '')) || DateTime.parse(transaction[index].saleDate ?? '').isAtSameMomentAs(fromDate)) && (toDate.isAfter(DateTime.parse(transaction[index].saleDate ?? '')) || DateTime.parse(transaction[index].saleDate ?? '').isAtSameMomentAs(toDate))
                                        ? Visibility(
                                            visible: (calculateTotalProductQtyNow(sales: transaction[index]) > 0),
                                            child: GestureDetector(
                                              onTap: () {
                                                SingleLossProfitScreen(
                                                  transactionModel: transaction[index],
                                                ).launch(context);
                                              },
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
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
                                                                (transaction[index].party?.name != null) ? transaction[index].party?.name ?? '' : transaction[index].party?.phone ?? '',
                                                                style: const TextStyle(fontSize: 16),
                                                              ),
                                                            ),
                                                            Text(
                                                              '#${transaction[index].invoiceNumber}',
                                                              style: const TextStyle(color: Colors.black),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 10),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                  decoration: BoxDecoration(color: transaction[index].dueAmount! <= 0 ? const Color(0xff0dbf7d).withOpacity(0.1) : const Color(0xFFED1A3B).withOpacity(0.1), borderRadius: const BorderRadius.all(Radius.circular(10))),
                                                                  child: Text(
                                                                    transaction[index].dueAmount! <= 0 ? lang.S.of(context).paid : lang.S.of(context).unPaid,
                                                                    style: TextStyle(color: transaction[index].dueAmount! <= 0 ? const Color(0xff0dbf7d) : const Color(0xFFED1A3B)),
                                                                  ),
                                                                ),

                                                                ///________Return_tag_________________________________________
                                                                ReturnedTagWidget(show: transaction[index].salesReturns?.isNotEmpty ?? false),
                                                              ],
                                                            ),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: [
                                                                Text(
                                                                  DateFormat.yMMMd().format(DateTime.parse(transaction[index].saleDate ?? '')),
                                                                  style: const TextStyle(color: Colors.grey),
                                                                ),
                                                                const SizedBox(height: 5),
                                                                Text(
                                                                  DateFormat.jm().format(DateTime.parse(transaction[index].saleDate ?? '')),
                                                                  style: const TextStyle(color: Colors.grey),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                              Text(
                                                                '${lang.S.of(context).total} : $currency ${transaction[index].totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                                                style: const TextStyle(color: Colors.grey),
                                                              ),
                                                              const SizedBox(height: 5),
                                                              Text(
                                                                '${lang.S.of(context).profit} : $currency ${transaction[index].detailsSumLossProfit?.toStringAsFixed(2) ?? '0.00'}',
                                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                                              ).visible(!transaction[index].detailsSumLossProfit!.isNegative),
                                                              Text(
                                                                '${lang.S.of(context).loss}: $currency ${transaction[index].detailsSumLossProfit!.abs().toStringAsFixed(2)}',
                                                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                                              ).visible(transaction[index].detailsSumLossProfit!.isNegative),
                                                            ]),
                                                            personalData.when(data: (data) {
                                                              return Row(
                                                                children: [
                                                                  IconButton(
                                                                      onPressed: () async {
                                                                        totalProfit = 0;
                                                                        totalLoss = 0;
                                                                        PrintTransactionModel model = PrintTransactionModel(transitionModel: transaction[index], personalInformationModel: data);
                                                                        await printerData.printSalesThermalInvoiceNow(
                                                                          transaction: model,
                                                                          productList: model.transitionModel!.salesDetails,
                                                                          context: context,
                                                                        );
                                                                      },
                                                                      icon: const Icon(
                                                                        FeatherIcons.printer,
                                                                        color: Colors.grey,
                                                                      )),
                                                                  IconButton(
                                                                      onPressed: () => toast(
                                                                            lang.S.of(context).comingSoon,
                                                                            //'Coming Soon'
                                                                          ),
                                                                      icon: const Icon(
                                                                        FeatherIcons.share,
                                                                        color: Colors.grey,
                                                                      )).visible(false),
                                                                ],
                                                              );
                                                            }, error: (e, stack) {
                                                              return Text(e.toString());
                                                            }, loading: () {
                                                              //return const Text('Loading');
                                                              return Text(
                                                                lang.S.of(context).loading,
                                                                //'Loading'
                                                              );
                                                            }),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 0.5,
                                                    width: context.width(),
                                                    color: Colors.grey,
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container();
                                  },
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Text(
                                lang.S.of(context).pleaseMakeASaleFirst,
                                //"Please make a sale first"
                              ),
                            );
                    }, error: (e, stack) {
                      return Text(e.toString());
                    }, loading: () {
                      return const Center(child: CircularProgressIndicator());
                    }),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
