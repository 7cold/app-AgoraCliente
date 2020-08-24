import 'dart:async';
import 'dart:io';
import 'package:agora_flutter_quickstart/src/controller/controller.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import './call.dart';
import 'package:http/http.dart' as http;

class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();
}

class IndexState extends State<IndexPage> {
  MyController controller = Get.put(MyController());

  /// create a channelController to retrieve text value
  final _channelController = TextEditingController();

  /// if channel textField is validated to have error
  bool _validateError = false;

  ClientRole _role = ClientRole.Broadcaster;

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void dispose() {
    // dispose input controller
    _channelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    iniciarFirebaseListeners();
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void iniciarFirebaseListeners() {
    if (Platform.isIOS) requisitarPermissoesParaNotificacoesNoIos();

    _firebaseMessaging.subscribeToTopic("allDevices");

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('mensagem recebida $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  void requisitarPermissoesParaNotificacoesNoIos() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  sendSms() {
    String DATA =
        "{\"notification\": {\"body\": \"Tem alguem em usa casa!\"}, \"priority\": \"high\", \"data\": {\"click_action\": \"FLUTTER_NOTIFICATION_CLICK\", \"id\": \"1\", \"status\": \"done\"}, \"to\": \"/topics/allDevices\"}";
    http.post("https://fcm.googleapis.com/fcm/send", body: DATA, headers: {
      "Content-Type": "application/json",
      "Authorization":
          "key=AAAALvDgjnU:APA91bEQWtyaJb_CWVKEUSq2uYJYZ7tSzG-e1erNntY0b1Tpl6bxfmrMK50PEKC36-Yy1vwvMNTlN_7CdmSmIay7cWX_Jsw6rWuG4OHQ-AB5G71pIRmaL1neAhtWh2deOnf8aI4W_NlK"
    });
    print(DATA);
  }

  @override
  Widget build(BuildContext context) {
    _channelController.text = "live";
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        bottomSheet: InkWell(
          onTap: () {
            onJoin();
            sendSms();
          },
          child: Container(
            height: 160,
            color: CupertinoColors.activeGreen,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: Text(
              "Chamar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            )),
          ),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 400,
            child: Column(
              children: <Widget>[
                Column(
                  children: [
                    Text(
                      "Seja Bem Vindo",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    controller.changeStatus(true);
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      await _handleCameraAndMic();
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: _channelController.text,
            role: _role,
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic() async {
    await PermissionHandler().requestPermissions(
      [PermissionGroup.camera, PermissionGroup.microphone],
    );
  }
}
