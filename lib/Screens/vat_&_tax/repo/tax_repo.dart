import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../Const/api_config.dart';
import '../../../Repository/constant_functions.dart';
import '../../../http_client/custome_http_client.dart';
import '../model/vat_model.dart';
import '../provider/text_repo.dart';

class TaxRepo {
  Future<List<VatModel>> fetchAllTaxes({String? taxType}) async {
    final uri = Uri.parse('${APIConfig.url}/vats?type=$taxType');

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': await getAuthToken(),
    });

    if (response.statusCode == 200) {
      final parsedData = jsonDecode(response.body) as Map<String, dynamic>;

      final partyList = parsedData['data'] as List<dynamic>;
      return partyList.map((category) => VatModel.fromJson(category)).toList();
      // Parse into Party objects
    } else {
      throw Exception('Failed to fetch tax list');
    }
  }

  Future<void> createSingleTax({
    required WidgetRef ref,
    required BuildContext context,
    required num taxRate,
    required String taxName,
    required bool status,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/vats');
    final requestBody = jsonEncode({
      'name': taxName,
      'rate': taxRate,
    });

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);
      var responseData = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: requestBody,
      );

      final parsedData = jsonDecode(responseData.body);

      EasyLoading.dismiss();
      if (responseData.statusCode == 200) {
        ref.refresh(taxProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tax creation failed: ${parsedData}')));
        return;
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      // return null;
    }
  }

  Future<void> createGroupTax({
    required WidgetRef ref,
    required BuildContext context,
    required String taxName,
    required List<num> taxIds,
    required bool status,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/vats');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
    request.fields.addAll({
      'name': taxName,
    });

    if (taxIds.isNotEmpty) {
      int index = 0;
      for (var element in taxIds) {
        request.fields['vat_ids[$index]'] = element.toString();
        index++;
      }
    }

    try {
      final response = await customHttpClient.uploadFile(
        url: uri,
        fields: request.fields,
      );
      // final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final parsedData = jsonDecode(responseData);

      EasyLoading.dismiss();
      print(response.statusCode);
      print(responseData);
      if (response.statusCode == 200) {
        print('45235');
        ref.refresh(taxProvider);
      } else if (response.statusCode == 403) {
        throw Exception('Failed to update tax');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tax creation failed: ${parsedData['message']}')));
        return;
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      // return null;
    }
  }

  ///________Update_Single_Tax__________________________________________
  Future<void> updateSingleTax({
    required num id,
    required String name,
    required num rate,
    required bool status,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/vats/$id');
    final requestBody = jsonEncode({
      'rate': rate,
      'name': name,
      'status': status,
      '_method': 'put',
    });

    try {
      CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

      final response = await customHttpClient.post(
        url: uri,
        addContentTypeInHeader: true,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        ref.refresh(taxProvider);
      } else {
        throw Exception('Failed to update tax. Status Code: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error updating income: $error');
      throw Exception('Error updating income: $error');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> updateGroupTax({
    required WidgetRef ref,
    required BuildContext context,
    required num id,
    required String taxName,
    required List<num> taxIds,
    required bool status,
  }) async {
    final uri = Uri.parse('${APIConfig.url}/vats/$id');
    CustomHttpClient customHttpClient = CustomHttpClient(client: http.Client(), context: context, ref: ref);

    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = await getAuthToken();
    request.fields.addAll({
      'name': taxName,
      'status': status ? '1' : "0",
      '_method': 'put',
    });

    if (taxIds.isNotEmpty) {
      int index = 0;
      for (var element in taxIds) {
        request.fields['vat_ids[$index]'] = element.toString();
        index++;
      }
    }

    try {
      final response = await customHttpClient.uploadFile(
        url: uri,
        fields: request.fields,
      );
      // final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final parsedData = jsonDecode(responseData);

      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        ref.refresh(taxProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tax creation failed: ${parsedData['message']}')));
        return;
      }
    } catch (error) {
      // Handle unexpected errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      // return null;
    }
  }

  ///________Delete_Tax______________________________________________________
  Future<bool> deleteTax({required String id, required BuildContext context, required WidgetRef ref}) async {
    try {
      final token = await getAuthToken();
      if (token.isEmpty) {
        throw Exception('Authentication token is missing or empty');
      }

      final url = Uri.parse('${APIConfig.url}/vats/$id');
      CustomHttpClient customHttpClient = CustomHttpClient(ref: ref, context: context, client: http.Client());
      final response = await customHttpClient.delete(url: url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error deleting tax: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error during delete operation: $error');
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }
}
