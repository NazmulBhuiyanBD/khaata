import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/bar_code_scaner_widget.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';

class SaleProductsList extends StatefulWidget {
  const SaleProductsList({super.key, this.customerModel});
  final Party? customerModel;

  @override
  State<SaleProductsList> createState() => _SaleProductsListState();
}

class _SaleProductsListState extends State<SaleProductsList> {
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Consumer(builder: (context, ref, __) {
        final cartProvider = ref.watch(cartNotifier);
        final productList = ref.watch(productProvider);

        return Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(lang.S.of(context).addItems),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// QR FIELD
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: codeController,
                        textFieldType: TextFieldType.NAME,
                        onChanged: (value) {
                          setState(() => productCode = value);
                        },
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: lang.S.of(context).productCode,
                          hintText: "Scan product QR code",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => BarcodeScannerWidget(
                              onBarcodeFound: (code) {
                                setState(() {
                                  productCode = code;
                                  codeController.text = code;
                                });
                              },
                            ),
                          );
                        },
                        child: const BarCodeButton(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Expanded(
                  child: productList.when(
                    data: (products) {
                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          /// FIXED: Define productPrice locally inside the builder
                          final num productPrice;

                          if (widget.customerModel?.type?.contains('Dealer') == true) {
                            productPrice = products[i].productDealerPrice ?? 0;
                          } else if (widget.customerModel?.type?.contains('Wholesaler') == true) {
                            productPrice = products[i].productWholeSalePrice ?? 0;
                          } else {
                            productPrice = products[i].productSalePrice ?? 0;
                          }

                          /// FILTER
                          bool isVisible = products[i]
                                  .productName!
                                  .toLowerCase()
                                  .contains(productCode.toLowerCase()) ||
                              products[i].productCode == productCode ||
                              productCode == '0000';

                          if (!isVisible) return const SizedBox();

                          return GestureDetector(
                            onTap: () {
                              if ((products[i].productStock ?? 0) <= 0) {
                                EasyLoading.showError("Out of stock");
                                return;
                              }

                              AddToCartModel cartItem = AddToCartModel(
                                productId: products[i].id ?? 0,
                                productName: products[i].productName,
                                productCode: products[i].productCode,
                                unitPrice: productPrice.toString(), // Uses the local correct price
                                productPurchasePrice: products[i].productPurchasePrice,
                                stock: products[i].productStock,
                                quantity: 1,
                              );

                              cartProvider.addToCartRiverPod(
                                  cartItem: cartItem, fromEditSales: false);

                              Navigator.pop(context);
                            },
                            child: ProductCard(
                              productTitle: products[i].productName ?? '',
                              productPrice: productPrice, // Passes the local correct price
                              productImage: products[i].productPicture,
                              stock: products[i].productStock ?? 0,
                              size: products[i].size,
                              color: products[i].color,
                              weight: products[i].weight,
                              capacity: products[i].capacity,
                              brandName: products[i].brand?.brandName,
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(e.toString()),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.productTitle,
    required this.productPrice,
    required this.productImage,
    required this.stock,
    this.size,
    this.color,
    this.weight,
    this.capacity,
    this.brandName,
  });

  final String productTitle;
  final num productPrice;
  final num stock;
  final String? productImage;

  final String? size;
  final String? color;
  final String? weight;
  final String? capacity;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    image: productImage == null
                        ? DecorationImage(
                            image: AssetImage(noProductImageUrl),
                            fit: BoxFit.cover,
                          )
                        : DecorationImage(
                            image: NetworkImage("${APIConfig.domain}$productImage"),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (size?.isNotEmpty == true) Text("Size: $size"),
                      if (color?.isNotEmpty == true) Text("Color: $color"),
                      if (weight?.isNotEmpty == true) Text("Weight: $weight"),
                      if (capacity?.isNotEmpty == true) Text("Capacity: $capacity"),
                      Text("Stock: $stock"),
                      if (brandName?.isNotEmpty == true)
                        Text(brandName!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$currency$productPrice",
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}