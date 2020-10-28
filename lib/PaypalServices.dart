import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert' as convert;
import 'package:http_auth/http_auth.dart';

class PaypalServices {
  String domain;
  String clientId;
  String secret;
  String accesstokenUrl;
  String createorderUrl;
  PaypalServices(
      {this.domain,
      this.clientId,
      this.secret,
      this.accesstokenUrl,
      this.createorderUrl});

  // for getting the access token from Paypal
  Future<String> getAccessToken() async {
    try {
      var client = BasicAuthClient(clientId, secret);
      var response = await client.post('$accesstokenUrl');
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body);
        return body["access_token"];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // for creating the order payment request with Paypal
  Future<Map<String, String>> createPaypalPayment(
      transactions, accessToken) async {
    try {
      var response = await http.post("$createorderUrl",
          body: convert.jsonEncode(transactions),
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer ' + accessToken
          });

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];

          String authorizeUrl = "";
          String approvalUrl = "";
          final item = links.firstWhere((o) => o["rel"] == "approve",
              orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 = links.firstWhere((o) => o["rel"] == "authorize",
              orElse: () => null);
          if (item1 != null) {
            authorizeUrl = item1["href"];
          }
          return {"authorizeUrl": authorizeUrl, "approvalUrl": approvalUrl};
        }
        return null;
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  //authorize the order payment request with Paypal
  Future<String> authorizePaypalPayment(authorizeUrl, accessToken) async {
    try {
      var response = await http.post(authorizeUrl, body: null, headers: {
        "content-type": "application/json",
        'Authorization': 'Bearer ' + accessToken
      });

      final body = convert.jsonDecode(response.body);
      final links =
          body["purchase_units"][0]["payments"]["authorizations"][0]["links"];
      if (response.statusCode == 201 && body["status"] == "COMPLETED") {
        if (links != null && links.length > 0) {
          String captureUrl = "";
          final item1 = links.firstWhere((o) => o["rel"] == "capture",
              orElse: () => null);
          if (item1 != null) {
            captureUrl = item1["href"];
          }
          return captureUrl;
        }
        return null;
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  // for executing the payment transaction with capture url got during create createPaypalPayment call.
  Future<String> executePayment(captureUrl, accessToken) async {
    try {
      var response = await http.post(captureUrl, body: null, headers: {
        "content-type": "application/json",
        'Authorization': 'Bearer ' + accessToken
      });

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 201 && body["status"] == "COMPLETED") {
        return body["id"];
      }
      //TODO:handle if payment is failed
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
