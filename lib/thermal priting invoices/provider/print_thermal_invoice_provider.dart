import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../../constant.dart';
import '../../model/sale_transaction_model.dart';
import '../model/print_transaction_model.dart';
import '../thermal_invoice_due.dart';
import '../thermal_invoice_purchase.dart';
import '../thermal_invoice_sales.dart';

final thermalPrinterProvider = ChangeNotifierProvider((ref) => ThermalPrinter());

class ThermalPrinter extends ChangeNotifier {
  List<BluetoothInfo> availableBluetoothDevices = [];
  bool isBluetoothConnected = false;

  Future<void> getBluetooth() async {
    availableBluetoothDevices = await PrintBluetoothThermal.pairedBluetooths;
    isBluetoothConnected = await PrintBluetoothThermal.connectionStatus;
    notifyListeners();
  }

  Future<bool> setConnect(String mac) async {
    bool status = false;
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (result == true) {
      isBluetoothConnected = true;
      status = true;
    }
    notifyListeners();
    return status;
  }

  Future<dynamic> listOfBluDialog({required BuildContext context}) async {
    return showCupertinoDialog(
      context: context,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: CupertinoAlertDialog(
              insetAnimationCurve: Curves.bounceInOut,
              content: Container(
                height: availableBluetoothDevices.isNotEmpty ? (availableBluetoothDevices.length * 80).toDouble() : 150,
                width: double.maxFinite,
                child: availableBluetoothDevices.isNotEmpty
                    ? ListView.builder(
                        padding: EdgeInsets.all(0), // Removed padding from ListView
                        shrinkWrap: true,
                        itemCount: availableBluetoothDevices.isNotEmpty ? availableBluetoothDevices.length : 0,
                        itemBuilder: (context1, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.all(0), // Removed padding from ListTile
                            onTap: () async {
                              BluetoothInfo select = availableBluetoothDevices[index];
                              bool isConnect = await setConnect(select.macAdress);
                              isConnect ? finish(context1) : toast(lang.S.of(context1).tryAgain);
                            },
                            title: Text(
                              availableBluetoothDevices[index].name,
                              style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              lang.S.of(context1).clickToConnect,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 40,
                              color: kMainColor,
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Not available',
                              style: TextStyle(fontSize: 14, color: kGreyTextColor),
                            )
                          ],
                        ),
                      ),
              ),
              title: Text(
                'Connect Your Device',
                textAlign: TextAlign.start,
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(
                    lang.S.of(context).cancel,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> printSalesThermalInvoiceNow({required PrintTransactionModel transaction, required List<SalesDetails>? productList, required BuildContext context}) async {
    await getBluetooth();
    isBluetoothConnected ? SalesThermalPrinterInvoice().printSalesTicket(printTransactionModel: transaction, productList: productList) : listOfBluDialog(context: context);
  }

  Future<void> printPurchaseThermalInvoiceNow({required PrintPurchaseTransactionModel transaction, required List<PurchaseDetails>? productList, required BuildContext context}) async {
    await getBluetooth();
    isBluetoothConnected ? PurchaseThermalPrinterInvoice().printPurchaseThermalInvoice(printTransactionModel: transaction, productList: productList) : listOfBluDialog(context: context);
  }

  Future<void> printDueThermalInvoiceNow({required PrintDueTransactionModel transaction, required BuildContext context}) async {
    await getBluetooth();
    isBluetoothConnected ? DueThermalPrinterInvoice().printDueTicket(printDueTransactionModel: transaction) : listOfBluDialog(context: context);
  }
}
