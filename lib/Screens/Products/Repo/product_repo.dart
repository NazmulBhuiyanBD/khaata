//ignore_for_file: file_names, unused_element, unused_local_variable
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../Model/product_model.dart';

class ProductRepo {
  Future<List<ProductModel>> fetchAllProducts() async {
    final uri = Uri.parse('${APIConfig.url}/products');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => ProductModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Products');
    }
  }

  Future<void> addProduct({
    required WidgetRef ref,
    required BuildContext context,
    required String productName,
    required String categoryId,
    required String productCode,
    required String productStock,
    required String productSalePrice,
    required String productPurchasePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
    String? vatId,
    String? vatType,
    String? vatAmount,
    String? profitMargin,
    String? lowStock,
    String? expDate,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/products');

    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
    request.fields.addAll({
      "productName": productName,
      "category_id": categoryId,
      "productCode": productCode,
      "productStock": productStock,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });
    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    if (brandId != null) request.fields['brand_id'] = brandId.toString();
    if (unitId != null) request.fields['unit_id'] = unitId;
    if (vatId != null) request.fields['vat_id'] = vatId;
    if (vatType != null) request.fields['vat_type'] = vatType;
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    // final response = await request.send();
    final response = await customHttpClient.uploadFile(url: uri, file: image, fileFieldName: 'productPicture', fields: request.fields);
    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);
    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added successful!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product creation failed: ${parsedData['message']}')));
    }
  }

  Future<bool> addForBulkUpload({
    required String productName,
    required String categoryId,
    required String productCode,
    required String productStock,
    required String productSalePrice,
    required String productPurchasePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/products');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
    request.fields.addAll({
      "productName": productName,
      "category_id": categoryId,
      "productCode": productCode,
      "productStock": productStock,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });
    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    if (brandId != null) request.fields['brand_id'] = brandId.toString();
    if (unitId != null) request.fields['unit_id'] = unitId;
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final parsedData = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<void> deleteProduct({
    required String id,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/products/$id';

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));

        var data1 = ref.refresh(productProvider);
      } else {
        final parsedData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete product: ${parsedData['message']}')));
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> updateProduct({
    required String productId,
    required WidgetRef ref,
    required BuildContext context,
    required String productName,
    required String productCode,
    String? categoryId,
    required String productSalePrice,
    required String productPurchasePrice,
    File? image,
    String? size,
    String? color,
    String? weight,
    String? capacity,
    String? type,
    String? brandId,
    String? unitId,
    String? productWholeSalePrice,
    String? productDealerPrice,
    String? productManufacturer,
    String? productDiscount,
    String? productStock,
    String? vatId,
    String? vatType,
    String? vatAmount,
    String? profitMargin,
    String? lowStock,
    String? expDate,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/products/$productId');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();

    request.fields['_method'] = 'put';
    request.fields.addAll({
      "productName": productName,
      "productCode": productCode,
      "productSalePrice": productSalePrice,
      "productPurchasePrice": productPurchasePrice,
    });

    if (size != null) request.fields['size'] = size;
    if (color != null) request.fields['color'] = color;
    if (weight != null) request.fields['weight'] = weight;
    if (capacity != null) request.fields['capacity'] = capacity;
    if (type != null) request.fields['type'] = type;
    request.fields['brand_id'] = brandId != null ? brandId.toString() : '';
    request.fields['unit_id'] = unitId != null ? unitId.toString() : '';
    if (categoryId != null) request.fields['category_id'] = categoryId;
    if (vatId != null) request.fields['vat_id'] = vatId;
    if (vatType != null) request.fields['vat_type'] = vatType;
    if (vatAmount != null) request.fields['vat_amount'] = vatAmount;
    if (profitMargin != null) request.fields['profit_percent'] = profitMargin;
    if (productWholeSalePrice != null) request.fields['productWholeSalePrice'] = productWholeSalePrice;
    if (productDealerPrice != null) request.fields['productDealerPrice'] = productDealerPrice;
    if (productManufacturer != null) request.fields['productManufacturer'] = productManufacturer;
    if (productDiscount != null) request.fields['productDiscount'] = productDiscount;
    if (productStock != null) request.fields['productStock'] = productStock;
    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes('productPicture', image.readAsBytesSync(), filename: image.path));
    }
    if (lowStock != null) request.fields['alert_qty'] = lowStock;
    if (expDate != null) request.fields['expire_date'] = expDate;

    print('Update response : ${request.fields}');
    final response = await customHttpClient.uploadFile(
      url: uri,
      file: image,
      fileFieldName: 'productPicture',
      fields: request.fields,
    );
    final responseData = await response.stream.bytesToString();

    final parsedData = jsonDecode(responseData);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated Successfully!')));
      var data1 = ref.refresh(productProvider);

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product Update failed: ${parsedData['message']}')));
    }
  }
}
