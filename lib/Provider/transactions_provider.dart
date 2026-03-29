import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Purchase/Model/purchase_transaction_model.dart';
import 'package:mobile_pos/Screens/Purchase/Repo/purchase_repo.dart';
import 'package:mobile_pos/Screens/Sales/Repo/sales_repo.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';

SaleRepo saleRepo = SaleRepo();

// --- SALES PROVIDERS ---
final salesTransactionProvider = FutureProvider<List<SalesTransactionModel>>((ref) => saleRepo.fetchSalesList());
final salesReturnTransactionProvider = FutureProvider<List<SalesTransactionModel>>((ref) => saleRepo.fetchSalesList(salesReturn: true));

// Search State
final salesSearchProvider = StateProvider<String>((ref) => "");

// Filtered Sales Provider
final filteredSalesProvider = Provider<AsyncValue<List<SalesTransactionModel>>>((ref) {
  final salesAsync = ref.watch(salesTransactionProvider);
  final searchString = ref.watch(salesSearchProvider).toLowerCase();

  return salesAsync.whenData((list) {
    if (searchString.isEmpty) return list;
    return list.where((sale) {
      // Logic: Search by Customer Name or Invoice Number
      // Based on your model: sale.party.name
      final customerName = sale.party?.name?.toLowerCase() ?? '';
      final invoice = sale.invoiceNumber?.toLowerCase() ?? '';
      
      return customerName.contains(searchString) || invoice.contains(searchString);
    }).toList();
  });
});

// --- PURCHASE PROVIDERS ---
PurchaseRepo repo = PurchaseRepo();
final purchaseTransactionProvider = FutureProvider<List<PurchaseTransaction>>((ref) => repo.fetchPurchaseList());
final purchaseReturnTransactionProvider = FutureProvider<List<PurchaseTransaction>>((ref) => repo.fetchPurchaseList(purchaseReturn: true));

// Purchase Search State
final purchaseSearchProvider = StateProvider<String>((ref) => "");

// Filtered Purchase Provider
final filteredPurchaseProvider = Provider<AsyncValue<List<PurchaseTransaction>>>((ref) {
  final purchaseAsync = ref.watch(purchaseTransactionProvider);
  final searchString = ref.watch(purchaseSearchProvider).toLowerCase();

  return purchaseAsync.whenData((list) {
    if (searchString.isEmpty) return list;
    return list.where((purchase) {
      // Assuming Purchase model follows similar structure: purchase.party.name
      final supplierName = purchase.party?.name?.toLowerCase() ?? ''; 
      final invoice = purchase.invoiceNumber?.toLowerCase() ?? '';
      
      return supplierName.contains(searchString) || invoice.contains(searchString);
    }).toList();
  });
});