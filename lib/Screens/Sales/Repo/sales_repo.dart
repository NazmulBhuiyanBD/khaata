import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/Provider/product_provider.dart';

import '../../../Const/api_config.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Provider/transactions_provider.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../../../model/sale_transaction_model.dart';
import '../../Customers/Provider/customer_provider.dart';

class SaleRepo {
  Future<List<SalesTransactionModel>> fetchSalesList({bool? salesReturn}) async {
    final uri = Uri.parse('${APIConfig.url}/sales${(salesReturn ?? false) ? "?returned-sales=true" : ''}');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => SalesTransactionModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch Sales List');
    }
  }

  Future<SalesTransactionModel?> createSale({
    required WidgetRef ref,
    required BuildContext context,
    required num? partyId,
    required String? customerPhone,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num unRoundedTotalAmount,
    required num totalAmount,
    required num roundingAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num? vatId,
    required num changeAmount,
    required bool isPaid,
    required String paymentType,
    required String roundedOption,
    required List<CartSaleProducts> products,
    required String discountType,
    required num shippingCharge,
    String? note,
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales');

    try {
      var request = http.MultipartRequest("POST", uri);

      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), ref: ref, context: context);
      request.headers.addAll({
        "Accept": 'application/json',
        'Authorization': await getAuthToken(),
        'Content-Type': 'multipart/form-data',
      });

      // JSON data fields
      request.fields.addAll({
        'party_id': partyId?.toString() ?? '',
        'customer_phone': customerPhone ?? '',
        'saleDate': purchaseDate,
        'discountAmount': discountAmount.toString(),
        'discount_percent': discountPercent.toString(),
        'totalAmount': totalAmount.toString(),
        'dueAmount': dueAmount.toString(),
        'paidAmount': (totalAmount - dueAmount).toString(),
        'change_amount': changeAmount.toString(),
        'vat_amount': vatAmount.toString(),
        'vat_percent': vatPercent.toString(),
        'isPaid': isPaid.toString(),
        'payment_type_id': paymentType,
        'discount_type': discountType,
        'shipping_charge': shippingCharge.toString(),
        'rounding_option': roundedOption,
        'rounding_amount': roundingAmount.toStringAsFixed(2),
        'actual_total_amount': unRoundedTotalAmount.toString(),
        'note': note ?? '',
        'products': jsonEncode(
          products.map((product) => product.toJson()).toList(),
        ),
      });
      if (vatId != null) {
        request.fields.addAll({
          'vat_id': vatId.toString(),
        });
      }
      // If an image is provided, attach it to the request
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      var streamedResponse = await customHttpClient.uploadFile(url: uri, file: image, fileFieldName: 'image', fields: request.fields, countentType: 'multipart/form-data');
      var response = await http.Response.fromStream(streamedResponse);
      final parsedData = jsonDecode(response.body);
      print('Sales Post: ${response.statusCode}');
      print('Sales Post: ${response.body}');

      if (response.statusCode == 200) {
        ref.refresh(productProvider);
        ref.refresh(partiesProvider);
        ref.refresh(salesTransactionProvider);
        ref.refresh(businessInfoProvider);
        ref.refresh(getExpireDateProvider(ref));
        ref.refresh(summaryInfoProvider);
        print('${parsedData['data']}');
        final data = SalesTransactionModel.fromJson(parsedData['data']);
        return data;
      } else {
        EasyLoading.dismiss().then(
          (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sales creation failed: ${parsedData['message']}',
                ),
              ),
            );
          },
        );
        return null;
      }
    } catch (error) {
      EasyLoading.dismiss().then(
        (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $error')),
          );
        },
      );
      return null;
    }
  }

  Future<void> updateSale({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required num? partyId,
    required String purchaseDate,
    required num discountAmount,
    required num discountPercent,
    required num unRoundedTotalAmount,
    required num totalAmount,
    required num dueAmount,
    required num vatAmount,
    required num vatPercent,
    required num? vatId,
    required num changeAmount,
    required num roundingAmount,
    required bool isPaid,
    required String paymentType,
    required String roundedOption,
    required List<CartSaleProducts> products,
    required String discountType,
    required num shippingCharge,
    String? note,
    File? image,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/sales/$id');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), ref: ref, context: context);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = await getAuthToken()
      ..headers['Content-Type'] = 'application/json'
      ..fields['_method'] = 'put'
      ..fields['party_id'] = partyId.toString()
      ..fields['saleDate'] = purchaseDate
      ..fields['discountAmount'] = discountAmount.toString()
      ..fields['discount_percent'] = discountPercent.toString()
      ..fields['totalAmount'] = totalAmount.toString()
      ..fields['dueAmount'] = dueAmount.toString()
      ..fields['paidAmount'] = (totalAmount - dueAmount).toString()
      ..fields['change_amount'] = changeAmount.toString()
      ..fields['vat_amount'] = vatAmount.toString()
      ..fields['vat_percent'] = vatPercent.toString()
      ..fields['isPaid'] = isPaid.toString()
      ..fields['payment_type_id'] = paymentType
      ..fields['discount_type'] = discountType
      ..fields['shipping_charge'] = shippingCharge.toString()
      ..fields['note'] = note ?? ''
      ..fields['rounding_option'] = roundedOption ?? ''
      ..fields['rounding_amount'] = roundingAmount.toStringAsFixed(2)
      ..fields['actual_total_amount'] = unRoundedTotalAmount.toString() ?? '';

    // Convert the list of products to a JSON string
    String productJson = jsonEncode(products.map((product) => product.toJson()).toList());
    request.fields['products'] = productJson;

    if (vatId != null) {
      request.fields.addAll({'vat_id': vatId.toString()});
    }

    // Add image if it exists
    if (image != null) {
      var imageFile = await http.MultipartFile.fromPath('image', image.path);
      request.files.add(imageFile);
    }

    try {
      var response = await customHttpClient.uploadFile(url: uri, fields: request.fields, fileFieldName: 'image', file: image);

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Added successful!').then((value) {
          ref.refresh(productProvider);
          ref.refresh(partiesProvider);
          ref.refresh(salesTransactionProvider);
          ref.refresh(businessInfoProvider);
          ref.refresh(getExpireDateProvider(ref));
          Navigator.pop(context);
        });
      } else {
        var responseData = await http.Response.fromStream(response);
        final parsedData = jsonDecode(responseData.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sales creation failed: ${parsedData['message']}')));
      }
    } catch (error) {
      EasyLoading.dismiss().then((value) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      });
    }
  }
}

class CartSaleProducts {
  final int productId;
  final num? price;
  final num? lossProfit;
  final num? quantities;

  CartSaleProducts({
    required this.productId,
    required this.price,
    required this.quantities,
    required this.lossProfit,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'price': price,
        'lossProfit': lossProfit,
        'quantities': quantities,
      };
}
