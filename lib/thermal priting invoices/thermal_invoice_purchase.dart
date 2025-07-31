import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../constant.dart';
import 'model/print_transaction_model.dart';

class PurchaseThermalPrinterInvoice {
  ///__________Purchase________________
  Future<void> printPurchaseThermalInvoice({required PrintPurchaseTransactionModel printTransactionModel, required List<PurchaseDetails>? productList}) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await getPurchaseTicket(printTransactionModel: printTransactionModel, productList: productList);
      if (printTransactionModel.purchaseTransitionModel?.details?.isNotEmpty ?? false) {
        await PrintBluetoothThermal.writeBytes(bytes);
      } else {
        toast('No Product Found');
      }
    } else {
      EasyLoading.showError('Unable to connect with printer');
    }
  }

  Future<List<int>> getPurchaseTicket({required PrintPurchaseTransactionModel printTransactionModel, required List<PurchaseDetails>? productList}) async {
    num productPrice({required num detailsId}) {
      return productList!.where((element) => element.id == detailsId).first.productPurchasePrice ?? 0;
    }

    num getReturndDiscountAmount() {
      num totalReturnDiscount = 0;
      if (printTransactionModel.purchaseTransitionModel?.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.purchaseTransitionModel!.purchaseReturns!) {
          if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.purchaseReturnDetails!) {
              totalReturnDiscount += ((productPrice(detailsId: details.purchaseDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    String productName({required num detailsId}) {
      return productList![productList.indexWhere(
            (element) => element.id == detailsId,
          )]
              .product
              ?.productName ??
          '';
    }

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (printTransactionModel.purchaseTransitionModel?.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.purchaseTransitionModel!.purchaseReturns!) {
          if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.purchaseReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    num getProductQuantity({required num detailsId}) {
      num totalQuantity = productList?.where((element) => element.id == detailsId).first.quantities ?? 0;
      if (printTransactionModel.purchaseTransitionModel?.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.purchaseTransitionModel!.purchaseReturns!) {
          if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.purchaseReturnDetails!) {
              if (details.purchaseDetailId == detailsId) {
                totalQuantity += details.returnQty ?? 0;
              }
            }
          }
        }
      }

      return totalQuantity;
    }

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in productList!) {
        // Calculate the total for each item without VAT
        num productPrice = element.productPurchasePrice ?? 0;
        num productQuantity = getProductQuantity(detailsId: element.id ?? 0);

        total += productPrice * productQuantity;
      }

      return total;
    }

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.text(printTransactionModel.personalInformationModel.companyName ?? '',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text('Seller :${printTransactionModel.purchaseTransitionModel?.user?.role == "shop-owner" ? "Admin" : printTransactionModel.purchaseTransitionModel?.user?.name}', styles: const PosStyles(align: PosAlign.center));

    if (printTransactionModel.personalInformationModel.address != null) {
      bytes += generator.text(printTransactionModel.personalInformationModel.address ?? '', styles: const PosStyles(align: PosAlign.center));
    }
    if (printTransactionModel.personalInformationModel.vatNumber != null) {
      bytes += generator.text("${printTransactionModel.personalInformationModel.vatName ?? 'VAT No :'}${printTransactionModel.personalInformationModel.vatNumber ?? ''}", styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text('Tel: ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.text('Name: ${printTransactionModel.purchaseTransitionModel?.party?.name ?? 'Guest'}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('mobile: ${printTransactionModel.purchaseTransitionModel?.party?.phone ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left));
    // bytes += generator.text('Purchase By: ${printTransactionModel.purchaseTransitionModel?.user?.name ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Invoice: ${printTransactionModel.purchaseTransitionModel?.invoiceNumber ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left), linesAfter: 1);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Item', width: 5, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();
    List.generate(productList?.length ?? 1, (index) {
      return bytes += generator.row([
        PosColumn(
            text: productList?[index].product?.productName ?? 'Not Defined',
            width: 5,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(productList?[index].productPurchasePrice ?? 0) ?? 'Not Defined',
            width: 2,
            styles: const PosStyles(
              align: PosAlign.center,
            )),
        PosColumn(text: formatPointNumber(getProductQuantity(detailsId: productList?[index].id ?? 0)), width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: "${(productList?[index].productPurchasePrice ?? 0) * getProductQuantity(detailsId: productList?[index].id ?? 0)}", width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    });

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Subtotal',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${getTotalForOldInvoice()}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Discount',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: formatPointNumber((printTransactionModel.purchaseTransitionModel?.discountAmount ?? 0) + getReturndDiscountAmount()),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: printTransactionModel.purchaseTransitionModel?.vat?.name ?? 'Vat',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: formatPointNumber((printTransactionModel.purchaseTransitionModel?.vatAmount ?? 0)),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Total',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: formatPointNumber((printTransactionModel.purchaseTransitionModel?.totalAmount ?? 0) + getTotalReturndAmount()),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    List<DateTime> returnedDates = [];

    ///_____Return_table_______________________________
    if (printTransactionModel.purchaseTransitionModel?.purchaseReturns?.isNotEmpty ?? false) {
      List.generate(printTransactionModel.purchaseTransitionModel?.purchaseReturns?.length ?? 0, (i) {
        bytes += generator.hr();
        if (!returnedDates.any((element) => element.isAtSameMomentAs(DateTime.tryParse(printTransactionModel.purchaseTransitionModel?.purchaseReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now()))) {
          bytes += generator.row([
            PosColumn(text: 'Return-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.purchaseTransitionModel?.purchaseReturns?[i].returnDate ?? DateTime.now().toString()))}', width: 7, styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
            PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          bytes += generator.hr();
        }

        List.generate(printTransactionModel.purchaseTransitionModel?.purchaseReturns?[i].purchaseReturnDetails?.length ?? 0, (index) {
          returnedDates.add(DateTime.tryParse(printTransactionModel.purchaseTransitionModel?.purchaseReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now());
          final product = printTransactionModel.purchaseTransitionModel?.purchaseReturns?[i].purchaseReturnDetails?[index];
          return bytes += generator.row([
            PosColumn(text: productName(detailsId: product?.purchaseDetailId ?? 0), width: 7, styles: const PosStyles(align: PosAlign.left)),
            PosColumn(text: product?.returnQty.toString() ?? 'Not Defined', width: 2, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: "${(product?.returnAmount ?? 0)}", width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        });
        //
      });
    }
    bytes += generator.hr();

    ///_____Total Returned Amount_______________________________
    if (printTransactionModel.purchaseTransitionModel?.purchaseReturns?.isNotEmpty ?? false) {
      bytes += generator.row([
        PosColumn(
            text: 'Returned Amount',
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: '${getTotalReturndAmount()}',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total Payable', width: 8, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: formatPointNumber(printTransactionModel.purchaseTransitionModel?.totalAmount ?? 0), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Payment Type:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printTransactionModel.purchaseTransitionModel?.paymentType?.name ?? 'N/A',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Payment Amount:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: formatPointNumber(((printTransactionModel.purchaseTransitionModel?.totalAmount ?? 0) - (printTransactionModel.purchaseTransitionModel?.dueAmount ?? 0)) + (printTransactionModel.purchaseTransitionModel?.changeAmount ?? 0)),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    if ((printTransactionModel.purchaseTransitionModel?.dueAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(
            text: 'Due Amount',
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(printTransactionModel.purchaseTransitionModel?.dueAmount ?? 0),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    if ((printTransactionModel.purchaseTransitionModel?.changeAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(
            text: 'Change Amount',
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(printTransactionModel.purchaseTransitionModel?.changeAmount ?? 0),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text(printTransactionModel.purchaseTransitionModel!.purchaseDate ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += generator.text('Note: Goods once sold will not be taken back or exchanged.', styles: const PosStyles(align: PosAlign.center, bold: false), linesAfter: 1);

    bytes += generator.qrcode(
      companyWebsite,
    );
    bytes += generator.text('Developed By: $companyName', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.cut();
    return bytes;
  }
}
