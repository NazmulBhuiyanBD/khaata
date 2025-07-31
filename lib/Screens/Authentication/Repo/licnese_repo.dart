import 'package:http/http.dart' as http;

import '../../../constant.dart';

class PurchaseModel {
  Future<bool> isActiveBuyer() async {
    final response = await http.get(Uri.parse('https://api.envato.com/v3/market/author/sale?code=$purchaseCode'), headers: {'Authorization': 'Bearer orZoxiU81Ok7kxsE0FvfraaO0vDW5tiz'});
    print("Purchase code${response.statusCode}");
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
