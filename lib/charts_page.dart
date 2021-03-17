import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
//import 'package:nfc_csem/entity/tags_entity.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
//import 'entity/tags_provider.dart';
import 'package:app_tcc/utils/database_helper.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> with TickerProviderStateMixin {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Container(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text('Tags Chart'))
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionBubble(
          items: <Bubble>[
            // Floating action menu item
            Bubble(
              title: "Home",
              iconColor: Colors.white,
              bubbleColor: Colors.blue,
              icon: Icons.home,
              titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              onPress: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
            Bubble(
              title: "VAquery",
              iconColor: Colors.white,
              bubbleColor: Colors.blue,
              icon: Icons.insert_chart_outlined,
              titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              onPress: () {
                _provideDB();
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
          icon: AnimatedIcons.list_view,
        ),
        body:
             Container(
        child: Text("top de mais"),
        color: Colors.amber,
        padding: EdgeInsets.all(20.0),
      ),

           /* SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                // Chart title
                title: ChartTitle(text: 'Temperature by time analyses'),
                // Enable legend
                legend: Legend(isVisible: true),
                // Enable tooltip
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
              LineSeries<Voltage, String>(
                  dataSource: _provideDB(),
                  xValueMapper: (Voltage tagsEntity, _) => tagsEntity.time,
                  yValueMapper: (Voltage tagsEntity, _) => tagsEntity.volt,
                  // Enable data label
                  dataLabelSettings: DataLabelSettings(isVisible: true))
            ])*/);
  }

  _provideDB() async {
    final todasLinhas = await DatabaseHelper.instance.varmsquery();
    var list = [];
   // print(todasLinhas);
    todasLinhas.forEach((k) => list.add(k));
    var mapa = todasLinhas.isNotEmpty ? todasLinhas[1] : 'initial text';
    print(mapa);
   //  print(list.to);
    //return list;
  }
}

class Voltage {
  Voltage(this.volt, this.time);
  final int volt;
  final String time;
}
