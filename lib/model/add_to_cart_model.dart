class AddToCartModel {
  AddToCartModel({required this.productId, this.productCode, this.productName, this.unitPrice, this.quantity = 1, this.productDetails, this.itemCartIndex = -1, this.uniqueCheck, this.stock, this.productPurchasePrice, this.lossProfit});

  num productId;
  dynamic productCode;
  String? productName;
  dynamic unitPrice;
  dynamic productPurchasePrice;
  dynamic uniqueCheck;
  num quantity = 1;
  dynamic productDetails;
  int itemCartIndex;
  num? stock;
  num? lossProfit;
}
