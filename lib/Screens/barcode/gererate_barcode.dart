import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/product_provider.dart';
import '../Products/Model/product_model.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  _BarcodeGeneratorScreenState createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  List<ProductModel> products = [];
  List<SelectedProduct> selectedProducts = [];
  bool showCode = true;
  bool showPrice = true;
  bool showName = true;

  void _addProduct(ProductModel product) {
    setState(() {
      final existingProduct = selectedProducts.firstWhere(
        (p) => p.product.productCode == product.productCode,
        orElse: () => SelectedProduct(product: product, quantity: 0),
      );

      if (existingProduct.quantity > 0) {
        existingProduct.quantity++;
        _showSnackBar('${product.productName} quantity increased.');
      } else {
        selectedProducts.add(SelectedProduct(product: product, quantity: 1));
        // _showSnackBar('${product.productName} added to the list.');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _preview() async {
    final pdf = pw.Document();
    List<pw.Widget> barcodeWidgets = [];

    for (var selectedProduct in selectedProducts) {
      for (int i = 0; i < selectedProduct.quantity; i++) {
        barcodeWidgets.add(pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (showName) pw.Text('${selectedProduct.product.productName}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.BarcodeWidget(drawText: showCode ? true : false, data: selectedProduct.product.productCode!, barcode: pw.Barcode.code128(), width: 80, height: 30, textPadding: 4, textStyle: const pw.TextStyle(fontSize: 8)),
            if (showPrice) pw.Text('Price: ${selectedProduct.product.productSalePrice}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.GridView(
              childAspectRatio: 0.68,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              crossAxisCount: 4,
              // Adjust the number of columns as needed
              children: barcodeWidgets.map((widget) => pw.Container(child: widget)).toList(),
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => await pdf.save());
    } catch (e) {
      print("Error generating PDF: $e");
    }
  }

  void _toggleCheckbox(bool value, Function(bool) updateFunction) {
    setState(() {
      updateFunction(value);
    });
  }

  final Map<int, TextEditingController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, __) {
        final productData = ref.watch(productProvider);
        final businessInfo = ref.watch(businessInfoProvider);
        return GlobalPopup(
          child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                centerTitle: true,
                title: Text(
                  lang.S.of(context).barcodeGenerator,
                ),
                backgroundColor: Colors.white,
              ),
              body: productData.when(
                data: (snapshot) {
                  products = snapshot; // Assuming snapshot is a List<ProductModel>
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //-----------------search_bar
                          TypeAheadField<ProductModel>(
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                autofocus: false,
                                decoration: kInputDecoration.copyWith(
                                  fillColor: kWhite,
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: kMainColor,
                                    ),
                                  ),
                                  hintText: lang.S.of(context).searchProduct,
                                  suffixIcon: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: kMainColor,
                                    ),
                                    child: const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                ),
                              );
                            },
                            suggestionsCallback: (pattern) {
                              return products.where((product) => product.productName!.toLowerCase().startsWith(pattern.toLowerCase())).toList();
                            },
                            itemBuilder: (context, ProductModel suggestion) {
                              return Container(
                                color: Colors.white, // Set the background color to white
                                child: ListTile(
                                  title: Text(suggestion.productName!),
                                  subtitle: Text('${lang.S.of(context).showCode}: ${suggestion.productCode?.toString() ?? '0'}'),
                                  trailing: Text('${lang.S.of(context).price}: ${suggestion.productSalePrice?.toString() ?? '0'}'),
                                ),
                              );
                            },
                            onSelected: (ProductModel value) {
                              _addProduct(value);
                            },
                          ),
                          const SizedBox(height: 14),
                          //-----------------check_box
                          Row(
                            children: [
                              Checkbox(
                                activeColor: kMainColor,
                                value: showCode,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                onChanged: (bool? value) => _toggleCheckbox(value!, (val) => showCode = val),
                              ),
                              Flexible(
                                child: Text(
                                  // 'Show Code',
                                  lang.S.of(context).showCode,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Checkbox(
                                activeColor: kMainColor,
                                value: showPrice,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                onChanged: (bool? value) => _toggleCheckbox(value!, (val) => showPrice = val),
                              ),
                              Flexible(
                                child: Text(
                                  // 'Show Price',
                                  lang.S.of(context).showPrice,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Checkbox(
                                activeColor: kMainColor,
                                value: showName,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                onChanged: (bool? value) => _toggleCheckbox(value!, (val) => showName = val),
                              ),
                              Flexible(
                                child: Text(
                                  lang.S.of(context).showName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          //-----------------data_table
                          selectedProducts.isNotEmpty
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
                                    showBottomBorder: true,
                                    horizontalMargin: 8,
                                    columns: [
                                      DataColumn(label: Text(lang.S.of(context).name)),
                                      DataColumn(label: Text(lang.S.of(context).stock)),
                                      DataColumn(label: Text(lang.S.of(context).quantity)),
                                      DataColumn(label: Text(lang.S.of(context).actions)),
                                    ],
                                    rows: selectedProducts.map((selectedProduct) {
                                      final controller = _controllers[selectedProduct.quantity];
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  selectedProduct.product.productName ?? 'N/A',
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                                Text(
                                                  selectedProduct.product.productCode ?? 'N/A',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: kGreyTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(selectedProduct.product.productStock?.toString() ?? '0'),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              height: 38,
                                              child: TextFormField(
                                                initialValue: selectedProduct.quantity.toString(),
                                                controller: controller,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedProduct.quantity = int.tryParse(value) ?? 1;
                                                  });
                                                },
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: kMainColor,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  selectedProducts.remove(selectedProduct); // Remove the whole product
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 50),
                                      const Icon(
                                        IconlyLight.document,
                                        color: kMainColor,
                                        size: 70,
                                      ),
                                      Text(
                                        lang.S.of(context).noItemSelected,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
                error: (e, stack) => Text(e.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              bottomNavigationBar: //-----------------submit_button
                  businessInfo.when(data: (details) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      backgroundColor: kMainColor,
                      minimumSize: const Size(double.maxFinite, 48),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // onPressed: selectedProducts.isNotEmpty
                    //     ? _preview
                    //     : () => ScaffoldMessenger.of(context).showSnackBar(
                    //           SnackBar(content: Text(lang.S.of(context).noProductSelected)),
                    //         ),
                    onPressed: () async {
                      if (selectedProducts.isNotEmpty) {
                        await _preview(); // ✅ Properly calling the function
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.S.of(context).noProductSelected)),
                        );
                      }
                    },

                    label: Text(
                      lang.S.of(context).previewPdf,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }, error: (e, stack) {
                return Text(e.toString());
              }, loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              })),
        );
      },
    );
  }
}

class SelectedProduct {
  final ProductModel product;
  int quantity;

  SelectedProduct({required this.product, required this.quantity});
}
