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
            Column(
                children: <Widget>[
                  Text("Credit Card"),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "",
                    ),
                    controller: creditCard,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                  )
                ],
            ),
            Column(
              children: <Widget>[
                Text("Exp Month"),
                TextField(
                    decoration: InputDecoration(
                      hintText: "",
                    ),
                    controller: expMonth,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                )
              ],
            ),
            Column(
              children: <Widget>[
                Text("Exp Year"),
                TextField(
                  decoration: InputDecoration(
                    hintText: "",
                  ),
                  controller: expYear,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                )
              ],
            ),
            Column(
              children: <Widget>[
                Text("Cvv"),
                TextField(
                  decoration: InputDecoration(
                    hintText: "",
                  ),
                  controller: cvv,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                )
              ],
            ),
            Column(
              children: <Widget>[
                Text("Email"),
                TextField(
                  decoration: InputDecoration(
                    hintText: "",
                  ),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                )
              ],
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: SizedBox(
                height: 50,
                child: RaisedButton(
                  onPressed: () => process(),
                  color: Colors.yellowAccent,
                  child: new Text("Pay \$5", style: TextStyle(fontSize:17, fontWeight: FontWeight.w700, color: Colors.black)),
                  padding: EdgeInsets.fromLTRB(49, 15, 49, 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                      side: BorderSide(color: Colors.white, width: 3)
                  ),
                ),
              ),
              alignment: Alignment.topRight,
            )
          ],
        ),

      ),
    );
  }

  Future process() async {
    print("processing");
    creditCard.text = "4242424242424242";
    expMonth.text = "07";
    expYear.text = "2023";
    cvv.text = "123";

    if(!processing) {
      setState(() {
        processing = true;
      });

      showGlobalDialogNoOkay("Processing, please wait...", null);

      var datas = {'card[number]': '4242424242424242', 'card[exp_month]': '10', 'card[exp_year]' : '2023', 'card[cvc]' : '123'};

      var req = http.Request('post', Uri.parse(STRIPE_URL + TOKENS_ENDPOINT));
      req.headers['Authorization'] = "Bearer " + STRIPE_KEY;
      req.headers['Content-Type'] = "application/x-www-form-urlencoded; charset=UTF-8";
//      req.headers['content-type'] = "text/plain; charset=UTF-8";

      print("content type " + req.headers['Content-Type']);

      Map<String, String> body = new HashMap();

      body['card[number]'] = "4242424242424242";
      body['card[exp_month]'] = "10";
      body['card[exp_year]'] = "2023";
      body['card[cvc]'] = "123";

      req.bodyFields = body;

      var respBody;

      try {

        http.StreamedResponse resp = await req.send();
        print("213");
        respBody = await resp.stream.bytesToString();

        print("response $respBody");
        var token = jsonDecode(respBody.body);

        print("token : $token");

        setState(() {
          processing = false;
        });

      } catch(e) {
        print(e.toString());
      }
    }

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
