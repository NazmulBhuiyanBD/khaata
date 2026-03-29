import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';

import '../Screens/Products/Repo/product_repo.dart';

ProductRepo productRepo = ProductRepo();
final productProvider = FutureProvider<List<ProductModel>>((ref) => productRepo.fetchAllProducts());

final productSearchProvider = StateProvider<String>((ref) => "");

final filteredProductProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productProvider);
  final searchString = ref.watch(productSearchProvider).toLowerCase();

  return productsAsync.whenData((products) {
    if (searchString.isEmpty) return products;
    return products.where((product) {
      return (product.productName?.toLowerCase().contains(searchString) ?? false) ||
             (product.productCode?.toLowerCase().contains(searchString) ?? false);
    }).toList();
  });
});
