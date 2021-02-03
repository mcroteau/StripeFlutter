import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool processing = false;

  var token;
  var customer;
  var product;
  var plan;

  final String STRIPE_KEY = "sk_test_pWfUa6jT1DnMsW2r7XhBBPHJ00CidZHHDm";
  final String STRIPE_URL = "https://api.stripe.com/v1/";

  final String CUSTOMERS_ENDPOINT = "customers";
  final String PRODUCTS_ENDPOINT = "products";
  final String PLANS_ENDPOINT = "plans";
  final String TOKENS_ENDPOINT = "tokens";


  TextEditingController email = new TextEditingController();
  TextEditingController creditCard = new TextEditingController();
  TextEditingController expMonth = new TextEditingController();
  TextEditingController expYear = new TextEditingController();
  TextEditingController cvv = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
              RaisedButton(
                  child: Text("Generate Plans"),
                  color: Colors.lightBlue,
                  textColor: Colors.white,
                  onPressed: save
              ),
              RaisedButton(
                  child: Text("Delete All Plans"),
                  color: Colors.redAccent,
                  textColor: Colors.white,
                  onPressed: delete
              )
            ]
          )
       )
      );
  }

  Future save() async {
    print("processing");

    if (!processing) {
      setState(() {
        processing = true;
      });

      showGlobalDialogNoOkay("Processing...", null);
      var f = createProduct().then((data) => createPlan(data));
      print("f : " + f.toString());
    }
  }

  Future delete() async{
    getPlans()
        .then((data) => deletePlans(data))
        .then((data) => getProducts(data))
        .then((data) => deleteProducts(data));
  }

  Future getPlans() async{
    Map<String, String> body = new HashMap();
    return sendReq(PLANS_ENDPOINT, 'get', body);
  }

  Future deletePlans(data) async{
    var plans = jsonDecode(data);
    print("data" + plans.toString());
    for(var plan in plans['data']){
      String name = plan['id'];
      print(name);
      Map<String, String> body = new HashMap();
      sendReq(PLANS_ENDPOINT + "/" + name, 'delete', body);
    }
  }


  Future getProducts(data) async{
    Map<String, String> body = new HashMap();
    return sendReq(PRODUCTS_ENDPOINT, 'get', body);
  }
  Future deleteProducts(data) async{
    var products = jsonDecode(data);
    print("data" + products.toString());
    for(var product in products['data']){
      String name = product['id'];
      print(name);
      Map<String, String> body = new HashMap();
      sendReq(PRODUCTS_ENDPOINT + "/" + name, 'delete', body);
    }
  }

  Future createProduct() async {
    Map<String, String> body = new HashMap();
    body['name'] = "MockProduct";
    return sendReq(PRODUCTS_ENDPOINT, 'post', body);
  }

  Future createPlan(data) async {
    print("create plan" + data);
    var json = jsonDecode(data);
    Map<String, String> body = new HashMap();
    body['amount'] = "500";
    body['interval'] = "month";
    body['currency'] = "usd";
    body['product'] = json['id'];
    return sendReq(PLANS_ENDPOINT, 'post', body);
  }


  Future sendReq(endpoint, method, body) async{
    var respBody;
    try {
      var req = http.Request(method, Uri.parse(STRIPE_URL + endpoint));
      req.headers['Authorization'] = "Bearer " + STRIPE_KEY;
      req.headers['Content-Type'] = "application/x-www-form-urlencoded; charset=UTF-8";
      req.bodyFields = body;

      http.StreamedResponse resp = await req.send();
      respBody = await resp.stream.bytesToString();

    } catch(e) {
      print(e.toString());
    }

    return respBody;
  }


  void showGlobalDialogNoOkay(String content, Function funct){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Message"),
            content: new Text(content),
          );
        }
    );
  }

}
