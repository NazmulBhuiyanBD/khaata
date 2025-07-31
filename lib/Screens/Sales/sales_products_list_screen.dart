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
  // ignore: library_private_types_in_public_api
  _SaleProductsListState createState() => _SaleProductsListState();
}

class _SaleProductsListState extends State<SaleProductsList> {
  // String dropdownValue = '';
  String productCode = '0000';
  TextEditingController codeController = TextEditingController();
  num productPrice = 0;
  String sentProductPrice = '';

  @override
  void initState() {
    // widget.catName == null ? dropdownValue = 'Fashion' : dropdownValue = widget.catName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Consumer(builder: (context, ref, __) {
        final providerData = ref.watch(cartNotifier);
        final productList = ref.watch(productProvider);

        return Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            title: Text(
              lang.S.of(context).addItems,
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: AppTextField(
                            controller: codeController,
                            textFieldType: TextFieldType.NAME,
                            onChanged: (value) {
                              setState(() {
                                productCode = value;
                              });
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: lang.S.of(context).productCode,
                              hintText: productCode == '0000' || productCode == '-1' ? 'Scan product QR code' : productCode,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (context) => BarcodeScannerWidget(
                                onBarcodeFound: (String code) {
                                  setState(() {
                                    productCode = code;
                                    codeController.text = productCode;
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
                  productList.when(data: (products) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          if (widget.customerModel != null && widget.customerModel!.type != null) {
                            if (widget.customerModel!.type!.contains('Retailer')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Dealer')) {
                              productPrice = products[i].productDealerPrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Wholesaler')) {
                              productPrice = products[i].productWholeSalePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Supplier')) {
                              productPrice = products[i].productPurchasePrice ?? 0;
                            } else if (widget.customerModel!.type!.contains('Guest')) {
                              productPrice = products[i].productSalePrice ?? 0;
                            }
                          } else {
                            productPrice = products[i].productSalePrice ?? 0;
                          }

                          return GestureDetector(
                            onTap: () async {
                              if ((products[i].productStock ?? 0) <= 0) {
                                EasyLoading.showError('Out of stock');
                              } else {
                                String sentProductPrice;
                                if (widget.customerModel != null && widget.customerModel!.type != null) {
                                  if (widget.customerModel!.type!.contains('Retailer')) {
                                    sentProductPrice = products[i].productSalePrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Dealer')) {
                                    sentProductPrice = products[i].productDealerPrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Wholesaler')) {
                                    sentProductPrice = products[i].productWholeSalePrice.toString();
                                  } else if (widget.customerModel!.type!.contains('Supplier')) {
                                    sentProductPrice = products[i].productPurchasePrice.toString();
                                  } else {
                                    sentProductPrice = products[i].productSalePrice.toString();
                                  }
                                } else {
                                  sentProductPrice = products[i].productSalePrice.toString();
                                }

                                AddToCartModel cartItem = AddToCartModel(
                                  productName: products[i].productName,
                                  unitPrice: sentProductPrice,
                                  productCode: products[i].productCode,
                                  productPurchasePrice: products[i].productPurchasePrice,
                                  stock: (products[i].productStock ?? 0),
                                  productId: products[i].id ?? 0,
                                  quantity: (products[i].productStock ?? 0) < 1 ? (products[i].productStock ?? 0) : 1,
                                );
                                providerData.addToCartRiverPod(cartItem: cartItem, fromEditSales: false);
                                Navigator.pop(context);
                              }
                            },
                            child: ProductCard(
                              productTitle: products[i].productName.toString(),
                              productDescription: products[i].brand?.brandName ?? '',
                              productPrice: productPrice,
                              productImage: products[i].productPicture,
                              stock: products[i].productStock ?? 0,
                            ).visible((products[i].productCode == productCode || productCode == '0000' || productCode == '-1') && productPrice != '0' || products[i].productName!.toLowerCase().contains(productCode.toLowerCase())),
                          );
                        });
                  }, error: (e, stack) {
                    return Text(e.toString());
                  }, loading: () {
                    return const Center(child: CircularProgressIndicator());
                  }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ignore: must_be_immutable
class ProductCard extends StatefulWidget {
  ProductCard({Key? key, required this.productTitle, required this.productDescription, required this.productPrice, required this.productImage, required this.stock}) : super(key: key);

  // final Product product;
  String productTitle, productDescription;
  num productPrice, stock;
  String? productImage;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  num quantity = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, ref, __) {
      final providerData = ref.watch(cartNotifier);
      for (var element in providerData.cartItemList) {
        if (element.productName == widget.productTitle) {
          quantity = element.quantity;
        }
      }

      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: widget.productImage == null
                          ? BoxDecoration(
                              image: DecorationImage(image: AssetImage(noProductImageUrl), fit: BoxFit.cover),
                              borderRadius: BorderRadius.circular(90.0),
                            )
                          : BoxDecoration(
                              image: DecorationImage(image: NetworkImage("${APIConfig.domain}${widget.productImage}"), fit: BoxFit.cover),
                              borderRadius: BorderRadius.circular(90.0),
                            ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.productTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                //'Stock: ${widget.stock}',
                                '${lang.S.of(context).stocks}${widget.stock}',
                              ),
                              // const SizedBox(width: 5),
                              // Text(
                              //   ' X $quantity',
                              //   style: GoogleFonts.jost(
                              //     fontSize: 14.0,
                              //     color: Colors.grey.shade500,
                              //   ),
                              // ).visible(quantity != 0),
                            ],
                          ),
                          Text(
                            widget.productDescription,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currency${widget.productPrice}',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      );
    });
  }
}
