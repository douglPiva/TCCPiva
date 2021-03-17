import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:ssh/ssh.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:app_tcc/utils/database_helper.dart';
import 'package:flutter/scheduler.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:app_tcc/charts_page.dart';

//void main() => runApp(new MyApp());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: <String, WidgetBuilder>{
      // '/history': (context) => HistoryPage(),
      '/chart': (context) => ChartPage(),
    },
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  String _result = '';
  String _timer_result = '';
  String _node = '';
  String _outletStatus = "OFF";
  String _voltage = '0V';
  String _current = '0A';
  String _power = "0W";
  String _powerfactor = "0";
  List _array;
  Timer _timer;
  int index = 0;
  bool switchControl = false;
  var textHolder = 'Switch is OFF';
  Animation<double> _animation;
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    super.initState();
    // your code after page opens,splash keeps open until work is done
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 45), (timer) {
      _fetchDB();
      _fetchdata();
      setState(() {
        // print("Data updaded");
      });
    });
  }

  Future<void> _switchcmd(var cmd) async {
    var client = new SSHClient(
      host: "15.0.0.25",
      port: 22,
      username: "mtadm",
      passwordOrKey: "csemBR1234",
    );
    if (cmd == null) cmd = "2211";
    String result;
    String cmd64String = '"$cmd"';
    print(cmd64String);
    try {
      result = await client.connect();
      print(result);
      if (result == "session_connected") {
        String dd = '"data"';
        result = await client.execute(
            "mosquitto_pub -t lora/36-35-36-30-5b-39-70-13/down -m '{$dd:$cmd64String}'");
        client.disconnect();
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  Future<void> _fetchDB() async {
    var client = new SSHClient(
      host: "15.0.0.25",
      port: 22,
      username: "mtadm",
      passwordOrKey: "csemBR1234",
    );
    try {
      String result = await client.connect();
      if (result == "session_connected") {
        result = await client.connectSFTP();
        if (result == "sftp_connected") {
          var array = await client.sftpLs();
          setState(() {
            _result = result;
            _array = array;
          });
          index++;
          final String dir = (await getExternalStorageDirectory()).path;
          var filePath = await client.sftpDownload(
            path: "/media/card/app_database/lora_packets_CEMIG.db",
            toPath: "$dir/lora_packets_local.db",
            callback: (progress) {
              print(progress); // read download progress
            },
          );
          setState(() {
            _result = "Download Scessfull";
          });

          print("Download sucessfull");
          print(await client.disconnectSFTP());
          client.disconnect();
          // _fetch();
        }
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  Future<void> _fetchdata() async {
    final todasLinhas = await DatabaseHelper.instance.queryAllRows();
    var resMap = todasLinhas.last;
    _result = (resMap.isNotEmpty ? resMap['node'] : 'initial text').toString();
    if (_result == "36-35-36-30-5b-39-70-13") {
      setState(() {
        _outletStatus =
            ((resMap.isNotEmpty ? resMap['bma400_activity'] : 'initial text') ==
                    0xA1
                ? "ON"
                : "OFF");
        _voltage =
            (resMap.isNotEmpty ? resMap['VArms'] : 'initial text').toString() +
                'V';
        _current =
            (resMap.isNotEmpty ? resMap['IArms'] : 'initial text').toString() +
                'A';
        _power =
            (resMap.isNotEmpty ? resMap['PA'] : 'initial text').toString() +
                'W';
        String pf = "pf";
        _powerfactor =
            (resMap.isNotEmpty ? resMap['FPA'] : 'initial text').toString() +
                pf;

        print("O status é: $_outletStatus");
      });
    }
  }

  void toggleSwitch(bool value) {
    if (switchControl == false) {
      setState(() {
        switchControl = true;
        textHolder = 'Switch is ON';
      });
      print('Switch is ON');
      final vcalib = 0; // 0x45;
      final vmsb = ((12700 >> 8) | 0x00ff);
      final vlsb = (12700 | 0x00ff);
      final swcomand = 0x55;

      var cmd64 = base64.encode(
          [0x00, 0x9C, 0x31, 0x00, 0x00, 0x55, 0xA1]); //comando de downlink on
      print(base64.decode(cmd64));
      _switchcmd(cmd64);
      // Put your code here which you want to execute on Switch ON event.

    } else {
      setState(() {
        switchControl = false;
        textHolder = 'Switch is OFF';
      });
      print('Switch is OFF');
      final vcalib = 0; // 0x45;
      final vmsb = ((12700 >> 8) | 0x00ff);
      final vlsb = (12700 | 0x00ff);
      final swcomand = 0x55;

      var cmd64 = base64.encode(
          [0x00, 0x9C, 0x31, 0x00, 0x00, 0x55, 0xB2]); //comando de downlink off
      print(base64.decode(cmd64));
      _switchcmd(cmd64);
      // Put your code here which you want to execute on Switch OFF event.
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget renderButtons() {
      return ButtonTheme(
        child: ButtonBar(
          children: <Widget>[
            Transform.scale(
                scale: 1.5,
                child: Switch(
                  onChanged: toggleSwitch,
                  value: switchControl,
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.green,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                )),
            Text(
              '$textHolder',
              style: TextStyle(fontSize: 12, color: Colors.white),
            )
          ],
        ),
      );
    }

    BoxDecoration myBoxDecoration() {
      return BoxDecoration(
          border: Border.all(
            width: 1,
            color: Colors.blue,
          ),
          borderRadius: BorderRadius.all(
              Radius.circular(5.0) //         <--- border radius here
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 6), // changes position of shadow
            ),
          ],
          color: Colors.blue);
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('APP TOMADA TCC'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionBubble(
            items: <Bubble>[
              // Floating action menu item
              Bubble(
                title: "Charts",
                iconColor: Colors.white,
                bubbleColor: Colors.blue,
                icon: Icons.show_chart_rounded,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                onPress: () {
                  Navigator.pushNamed(context, '/chart');
                },
              ),
              //Floating action menu item
            ],
            animation: _animation,

            // On pressed change animation state
            onPress: () => _animationController.isCompleted
                ? _animationController.reverse()
                : _animationController.forward(),

            // Floating Action button Icon color
            iconColor: Colors.blue,

            // Flaoting Action button Icon
            icon: AnimatedIcons.list_view),
        body: Column(
          // shrinkWrap: true,
          // padding: EdgeInsets.all(5.0),
          children: <Widget>[
            Container(
              child: renderButtons(),
              alignment: Alignment.center,
              margin: EdgeInsets.all(10.0),
              padding: EdgeInsets.all(10.0),
              decoration: myBoxDecoration(),
            ),
            Container(
              child: Text("Status Tomada: $_outletStatus",
                  style: TextStyle(color: Colors.white)),
              //color: Colors.red,
              decoration: myBoxDecoration(),
              alignment: Alignment.center,
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(20.0),
            ),
            SizedBox(
              height: 5,
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Text("Tensão: $_voltage",
                  style: TextStyle(color: Colors.white)),
              //color: Colors.white,
              alignment: Alignment.center,
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(20.0),
              decoration: myBoxDecoration(),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Text("Corrente: $_current",
                  style: TextStyle(color: Colors.white)),
              //color: Colors.green,
              alignment: Alignment.center,
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(20.0),
              decoration: myBoxDecoration(),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              child: Text("Potência Ativa: $_power",
                  style: TextStyle(color: Colors.white)),
              //color: Colors.amber,
              decoration: myBoxDecoration(),
              alignment: Alignment.center,
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(20.0),
            ),
            SizedBox(
              height: 5,
            ),
            Container(
                child: Text("Fator de Potência: $_powerfactor",
                    style: TextStyle(color: Colors.white)),
                //color: Colors.green,
                decoration: myBoxDecoration(),
                alignment: Alignment.center,
                margin: EdgeInsets.all(20.0),
                padding: EdgeInsets.all(20.0)),
          ],
        ),
      ),
    );
  }
}
