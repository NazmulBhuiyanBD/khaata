//ignore_for_file: file_names, unused_element, unused_local_variable
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../model/payment_type_model.dart';
import '../provider/payment_type_provider.dart';

class PaymentTypeRepo {
  Future<List<PaymentTypeModel>> fetchAllPaymentType() async {
    final uri = Uri.parse('${APIConfig.url}/payment-types');

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': await getAuthToken(),
      });

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>;
        final categoryList = parsedData['data'] as List<dynamic>;
        return categoryList.map((category) => PaymentTypeModel.fromJson(category)).toList();
      } else {
        print('Response: ${response.statusCode}');
        print('Response: ${response.body}');
        // Handle specific error cases based on response codes
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to fetch categories');
      // Handle unexpected errors gracefully
      rethrow; // Re-throw to allow further handling upstream
    }
  }

  Future<void> managePaymentType({
    required WidgetRef ref,
    required BuildContext context,
    required PaymentTypeModel data,
  }) async {
    final uri = Uri.parse(
      '${APIConfig.url}/payment-types${data.id != null ? '/${data.id}' : ''}',
    );
    CustomHttpClient customHttpClient = CustomHttpClient(
      client: http.Client(),
      context: context,
      ref: ref,
    );

    try {
      Map<String, String> body = {
        if (data.id != null) '_method': 'put',
        ...data.toJson(),
      };

      var responseData = await customHttpClient.post(
        url: uri,
        body: body,
      );

      final parsedData = jsonDecode(responseData.body);

      if (responseData.statusCode == 200) {
        print('eswyfgseuyfgseygfysegfseygfseygfseygfseygfseygfesgfsegfseygf');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added successful!'),
          ),
        );
        var data1 = ref.refresh(paymentTypeProvider);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category creation failed: ${parsedData['message']}',
            ),
          ),
        );
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $error'),
        ),
      );
    }
  }

  Future<bool> deletePaymentType({
    required BuildContext context,
    required int id,
    required WidgetRef ref,
  }) async {
    final String apiUrl = '${APIConfig.url}/payment-types/$id';

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(
        url: Uri.parse(apiUrl),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String message = responseData['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete payment type.')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred.')),
      );
      return false;
    }
  }
}
