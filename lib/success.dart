import 'package:flutter/material.dart';

class SuccessRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: Text("Success Page")),
            body: Container(
                child: Center(
              child: Text(
                "Payment is successfull!",
                style: TextStyle(fontSize: 30),
              ),
            ))));
  }
}
