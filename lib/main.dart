import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:StripeFlutter/z.dart' as z;

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

  String planId;
  String tokenId;
  String customerId;
  String subscriptionId;

  bool processing = false;

  final String STRIPE_URL = "https://api.stripe.com/v1/";

  final String CUSTOMERS_ENDPOINT = "customers";
  final String PRODUCTS_ENDPOINT = "products";
  final String PLANS_ENDPOINT = "plans";
  final String TOKENS_ENDPOINT = "tokens";
  final String SUBSCRIPTIONS_ENDPOINT = "subscriptions";


  TextEditingController email = new TextEditingController();
  TextEditingController creditCard = new TextEditingController();
  TextEditingController expMonth = new TextEditingController();
  TextEditingController expYear = new TextEditingController();
  TextEditingController cvc = new TextEditingController();

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
//              RaisedButton(
//                  child: Text("Generate Plan"),
//                  color: Colors.blue,
//                  textColor: Colors.white,
//                  onPressed: save
//              ),
              RaisedButton(
                  child: Text("Subscribe"),
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: subscribe
              ),
              RaisedButton(
                  child: Text("Cancel Subscription"),
                  color: Colors.red,
                  textColor: Colors.white,
                  onPressed: cancel
              ),
              RaisedButton(
                  child: Text("Delete Plans"),
                  color: Colors.red,
                  textColor: Colors.white,
                  onPressed: delete
              ),
            ]
          )
       )
      );
  }


  Future cancel() async{
    if(!processing){
      setProcessing(true);
      Map<String, String> body = new HashMap();
      sendReq(SUBSCRIPTIONS_ENDPOINT + "/" + subscriptionId, 'delete', body)
          .then((data) => deleteCustomer(data));
    }
  }

  Future deleteCustomer(data) async{
    var json = jsonDecode(data);
    customerId = json['customer'];
    Map<String, String> body = new HashMap();
    sendReq(CUSTOMERS_ENDPOINT + "/" + customerId, 'delete', body)
      .then((data) => displayCanceled(json, data));
  }

  void displayCanceled(json, data){
    var customerJson = jsonDecode(data);
    String content = "Successfully canceled @ " + json['canceled_at'].toString();
    showGlobalDialogNoOkay(content, null);
    setProcessing(false);
  }

  Future subscribe() async{
    if (!processing) {
      setProcessing(true);
      createToken()
          .then((value) => createCustomer(value))
          .then((customerData) => createSubscription(customerData));
    }
  }

  Future createToken() async {
    Map<String, String> body = new HashMap();
    body['card[number]'] = "4242424242424242";
    body['card[exp_month]'] = "10";
    body['card[exp_year]'] = "2023";
    body['card[cvc]'] = "123";
    return sendReq(TOKENS_ENDPOINT, 'post', body);
  }

  Future createCustomer(value) async {
    var token = jsonDecode(value);
    print("token " + token['id']);
    tokenId = token['id'];
    Map<String, String> body = new HashMap();
    body['email'] = "croteau.mike@gmail.com";
    body['source'] = token['id'];
    return sendReq(CUSTOMERS_ENDPOINT, 'post', body);
  }
/*
cus_It8ERSRb4mqhSj
plan_It8CpRuJWL56O1
 */
  Future createSubscription(customerData){
    var json = jsonDecode(customerData);
    customerId = json['id'];
    Map<String, String> body = new HashMap();
    body['customer'] = json['id'];;
    body['items[0][price]'] = "price_1IJUtwFMDPZBpdm3UcXZIHyr";//TODO:replace with your price id, apologies...
    sendReq(SUBSCRIPTIONS_ENDPOINT, 'post', body)
        .then((data) => displayData(data));
  }

  void displayData(data){
    var json = jsonDecode(data);
    subscriptionId = json['id'];//what you will want to store to delete later.
    String content = "customer id: " + customerId + "\n" +
                      "subscription id : " + json['id'];
    showGlobalDialogNoOkay(content, null);
    setProcessing(false);
  }


  Future save() async {
    print("processing");

    if (!processing) {
      setProcessing(true);
      createProduct()
          .then((data) => createPlan(data))
          .then((data) => setPlanId(data));
    }
  }

  void setPlanId(data){
    print("data: " + data);
    var json = jsonDecode(data);
    planId = json['id'];
    setProcessing(false);
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

  Future delete() async{
    if (!processing) {
      setProcessing(true);
      getPlans()
          .then((data) => deletePlans(data))
          .then((data) => getProducts(data))
          .then((data) => deleteProducts(data));
    }
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

    setProcessing(false);
  }



  Future sendReq(endpoint, method, body) async{
    var respBody;
    try {
      var req = http.Request(method, Uri.parse(STRIPE_URL + endpoint));
      req.headers['Authorization'] = "Bearer " + z.STRIPE_KEY;
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
            title: new Text("Result"),
            content: new Text(content)
          );
        }
    );
  }

  bool setProcessing(b){
    setState(() {
      processing = b;
    });
    return true;
  }

}
