import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../constant.dart';
import 'model/print_transaction_model.dart';

class DueThermalPrinterInvoice {
  ///_________Due________________________
  Future<void> printDueTicket({required PrintDueTransactionModel printDueTransactionModel}) async {
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await getDueTicket(printDueTransactionModel: printDueTransactionModel);
      await PrintBluetoothThermal.writeBytes(bytes);
    } else {}
  }

  Future<List<int>> getDueTicket({required PrintDueTransactionModel printDueTransactionModel}) async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    // final ByteData data = await rootBundle.load('images/logo.png');
    // final Uint8List imageBytes = data.buffer.asUint8List();
    // final Image? imagez = decodeImage(imageBytes);
    // bytes += generator.image(imagez!);
    bytes += generator.text(printDueTransactionModel.personalInformationModel.companyName ?? '',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text('Seller :${printDueTransactionModel.dueTransactionModel?.user?.role == "shop-owner" ? 'Admin' : printDueTransactionModel.dueTransactionModel?.user?.name ?? ''}', styles: const PosStyles(align: PosAlign.center));

    if (printDueTransactionModel.personalInformationModel.address != null) {
      bytes += generator.text(printDueTransactionModel.personalInformationModel.address ?? '', styles: const PosStyles(align: PosAlign.center));
    }
    if (printDueTransactionModel.personalInformationModel.vatNumber != null) {
      bytes += generator.text("${printDueTransactionModel.personalInformationModel.vatName ?? 'VAT No :'}${printDueTransactionModel.personalInformationModel.vatNumber ?? ''}", styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text(printDueTransactionModel.personalInformationModel.phoneNumber ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.text('Received From: ${printDueTransactionModel.dueTransactionModel?.party?.name} ', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Mobile: ${printDueTransactionModel.dueTransactionModel?.party?.phone}', styles: const PosStyles(align: PosAlign.left));
    // bytes += generator.text('Received By: ${printDueTransactionModel.dueTransactionModel?.user?.name}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Invoice: ${printDueTransactionModel.dueTransactionModel?.invoiceNumber ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left), linesAfter: 1);

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Invoice', width: 8, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'Due', width: 4, styles: const PosStyles(align: PosAlign.center, bold: true)),
    ]);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: printDueTransactionModel.dueTransactionModel?.invoiceNumber ?? '',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printDueTransactionModel.dueTransactionModel!.totalDue.toString(),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
          )),
    ]);

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'Payment Type:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printDueTransactionModel.dueTransactionModel!.paymentType?.name ?? 'N/A',
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
          text: printDueTransactionModel.dueTransactionModel!.payDueAmount.toString(),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Remaining Due:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printDueTransactionModel.dueTransactionModel!.dueAmountAfterPay.toString(),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text(printDueTransactionModel.dueTransactionModel?.paymentDate ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += generator.qrcode(companyWebsite);
    bytes += generator.text('Developed By: $companyName', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.cut();
    return bytes;
  }
}
