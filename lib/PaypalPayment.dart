import 'dart:core';
import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'PaypalServices.dart';
import 'package:global_configuration/global_configuration.dart';
import './success.dart';

class PaypalPayment extends StatefulWidget {
  final Function onFinish;

  PaypalPayment({this.onFinish});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String approvalUrl;
  String authorizeUrl;
  String captureUrl;
  String accessToken;
  PaypalServices paypalservices = PaypalServices(
      domain: GlobalConfiguration().getString("domain"),
      clientId: GlobalConfiguration().getString("clientId"),
      secret: GlobalConfiguration().getString("secret"),
      accesstokenUrl: GlobalConfiguration().getString("accesstokenUrl"),
      createorderUrl: GlobalConfiguration().getString("createOrderUrl"));

  String returnURL = 'https://www.example.com';
  String cancelURL = 'https://www.cancel.com';

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await paypalservices.getAccessToken();

        final transactions = getOrderParams();
        final res =
            await paypalservices.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          setState(() {
            approvalUrl = res["approvalUrl"];
            authorizeUrl = res["authorizeUrl"];
          });
        }
      } catch (e) {
        print('exception: ' + e.toString());
        final snackBar = SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  // item name, price and quantity
  String itemName = 'iPhone X';
  String itemPrice = '0.01';
  int quantity = 1;

//TODO: the data to be passed to create payment change it according to your requirement.
// passed in request body during create payment
  Map<String, dynamic> getOrderParams() {
    Map<String, dynamic> requestbody = {
      "intent": "AUTHORIZE",
      //give redirect url in application contextobject when payment is approved.
      "application_context": {
        "return_url": returnURL,
        "cancel_url": cancelURL,
        "brand_name": "EXAMPLE INC",
        "landing_page": "BILLING",
        "shipping_preference": "SET_PROVIDED_ADDRESS",
        "user_action": "CONTINUE"
      },
      "purchase_units": [
        {
          "reference_id": "PUHF",
          "description": "Sporting Goods",
          "custom_id": "CUST-HighFashions",
          "soft_descriptor": "HighFashions",
          "amount": {
            "currency_code": "INR",
            "value": "220.00",
            "breakdown": {
              "item_total": {"currency_code": "INR", "value": "180.00"},
              "shipping": {"currency_code": "INR", "value": "20.00"},
              "handling": {"currency_code": "INR", "value": "10.00"},
              "tax_total": {"currency_code": "INR", "value": "20.00"},
              "shipping_discount": {"currency_code": "INR", "value": "10"}
            }
          },
          "items": [
            {
              "name": "T-Shirt",
              "description": "Green XL",
              "sku": "sku01",
              "unit_amount": {"currency_code": "INR", "value": "90.00"},
              "tax": {"currency_code": "INR", "value": "10.00"},
              "quantity": "1",
              "category": "PHYSICAL_GOODS"
            },
            {
              "name": "Shoes",
              "description": "Running, Size 10.5",
              "sku": "sku02",
              "unit_amount": {"currency_code": "INR", "value": "45.00"},
              "tax": {"currency_code": "INR", "value": "5.00"},
              "quantity": "2",
              "category": "PHYSICAL_GOODS"
            }
          ],
          "shipping": {
            "method": "Indian Postal Service",
            "name": {"full_name": "Rahul sharma"},
            "address": {
              "address_line_1": "123 Townsend St",
              "address_line_2": "Floor 6",
              "admin_area_2": "Tech Park",
              "admin_area_1": "uttar pardesh",
              "postal_code": "208001",
              "country_code": "IN"
            }
          }
        }
      ]
    };
    return requestbody;
  }

  @override
  Widget build(BuildContext context) {
    print(approvalUrl);

    if (approvalUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: WebView(
          initialUrl: approvalUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (NavigationRequest request) {
            //when payment is approved the request url will contain the return url given during create payment
            if (request.url.contains(returnURL)) {
              final uri = Uri.parse(request.url);
              final payerID = uri.queryParameters['PayerID'];
              if (payerID != null) {
                //Note:once payment is approved now authorize it and execute it here
                paypalservices
                    .authorizePaypalPayment(authorizeUrl, accessToken)
                    .then((captureUrl) {
                  paypalservices
                      .executePayment(captureUrl, accessToken)
                      .then((id) {
                    widget.onFinish(id);
                    //TODO: once payment is executed successfully rediect to success page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuccessRoute()),
                    );
                  });
                });
              } else {
                Navigator.of(context).pop();
              }
              // Navigator.of(context).pop();
            }
            if (request.url.contains(cancelURL)) {
              Navigator.of(context).pop();
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black,
          elevation: 0.0,
        ),
        body: Center(child: Container(child: CircularProgressIndicator())),
      );
    }
  }
}
