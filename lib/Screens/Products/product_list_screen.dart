import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/product_provider.dart'; 
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/product_category/category_list_screen.dart';
import 'package:mobile_pos/Screens/product_unit/unit_list.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../barcode/gererate_barcode.dart';
import '../product_brand/brands_list.dart';
import '../product_category/provider/product_category_provider/product_unit_provider.dart';
import 'Repo/product_repo.dart';
import 'Widgets/widgets.dart';
import 'add_product.dart';
import 'bulk product upload/bulk_product_upload_screen.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  bool _isRefreshing = false;
  TextEditingController searchController = TextEditingController();

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    ref.refresh(productProvider);
    ref.refresh(categoryProvider);

    await Future.delayed(const Duration(seconds: 1));
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, __) {
        final businessInfo = ref.watch(businessInfoProvider);
        
        // This now refers to the filteredProvider in lib/Provider/product_provider.dart
        final providerData = ref.watch(filteredProductProvider);
        final searchString = ref.watch(productSearchProvider);
        
        final _theme = Theme.of(context);

        return businessInfo.when(data: (details) {
          return GlobalPopup(
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: kWhite,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
                title: Text(lang.S.of(context).productList),
                actions: [
                  PopupMenuButton<int>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryList(isFromProductList: true))),
                        child: Row(children: [const Icon(IconlyBold.category, color: kGreyTextColor), const SizedBox(width: 10), Text(lang.S.of(context).productCategory)]),
                      ),
                      PopupMenuItem(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BrandsList(isFromProductList: true))),
                        child: Row(children: [const Icon(IconlyBold.bookmark, color: kGreyTextColor), const SizedBox(width: 10), Text(lang.S.of(context).brand)]),
                      ),
                      PopupMenuItem(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitList(isFromProductList: true))),
                        child: Row(children: [const Icon(Icons.scale, color: kGreyTextColor), const SizedBox(width: 10), Text(lang.S.of(context).productUnit)]),
                      ),
                    ],
                    offset: const Offset(0, 40),
                    color: kWhite,
                    padding: EdgeInsets.zero,
                    elevation: 2,
                  ),
                ],
                centerTitle: true,
              ),
              floatingActionButton: FloatingActionButton(
                  backgroundColor: kMainColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  onPressed: () async {
                    Navigator.pushNamed(context, '/AddProducts');
                  },
                  child: const Icon(Icons.add, color: kWhite)),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      controller: searchController,
                      onChanged: (value) {
                        ref.read(productSearchProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product by name or code...',
                        prefixIcon: const Icon(IconlyLight.search),
                        suffixIcon: searchString.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  ref.read(productSearchProvider.notifier).state = '';
                                },
                                child: const Icon(Icons.cancel, color: kMainColor),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBorderColorTextField),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => refreshData(ref),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: providerData.when(
                          data: (products) {
                            return products.isNotEmpty
                                ? ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    itemBuilder: (_, i) {
                                      final product = products[i];
                                      return ListTile(
                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                        contentPadding: const EdgeInsets.only(left: 16),
                                        leading: product.productPicture == null
                                            ? CircleAvatarWidget(name: product.productName, size: const Size(50, 50))
                                            : Container(
                                                height: 50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.all(Radius.circular(90)),
                                                  image: DecorationImage(
                                                    image: NetworkImage('${APIConfig.domain}${product.productPicture!}'),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                        title: Text(
                                          product.productName ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: _theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (product.size != null && product.size!.isNotEmpty)
                                              Text("Size: ${product.size}", style: _theme.textTheme.bodySmall?.copyWith(color: DAppColors.kSecondary)),
                                            Text(
                                              "${lang.S.of(context).stock} : ${product.productStock}",
                                              style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: DAppColors.kSecondary),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("$currency${product.productSalePrice}", style: const TextStyle(fontSize: 18)),
                                            PopupMenuButton<int>(
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProduct(productModel: product))),
                                                  value: 1,
                                                  child: Row(children: [const Icon(IconlyBold.edit, color: kGreyTextColor), const SizedBox(width: 10), Text(lang.S.of(context).edit)]),
                                                ),
                                                PopupMenuItem(
                                                  onTap: () async {
                                                    bool confirmDelete = await showDeleteAlert(context: context, itemsName: 'product');
                                                    if (confirmDelete) {
                                                      EasyLoading.show(status: lang.S.of(context).deleting);
                                                      await ProductRepo().deleteProduct(id: product.id.toString(), context: context, ref: ref);
                                                    }
                                                  },
                                                  value: 2,
                                                  child: Row(children: [const Icon(IconlyBold.delete, color: kGreyTextColor), const SizedBox(width: 10), Text(lang.S.of(context).delete)]),
                                                ),
                                              ],
                                              offset: const Offset(0, 40),
                                              color: kWhite,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context, index) => Divider(color: const Color(0xff808191).withOpacity(0.2)),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 40),
                                      child: Text(
                                        searchString.isEmpty ? lang.S.of(context).addProduct : "No product found",
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.0),
                                      ),
                                    ),
                                  );
                          },
                          error: (e, stack) => Text(e.toString()),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, error: (e, stack) => Text(e.toString()), loading: () => const Center(child: CircularProgressIndicator()));
      },
    );
  }
}