import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sistem_rs/features/hospital/model/hospital_model.dart';
import 'package:sistem_rs/features/master/model/room_model.dart';
import 'package:sistem_rs/features/hospital/screen/hospital_screen.dart';
import 'package:sistem_rs/features/room/screen/room_screen.dart';
import 'package:sistem_rs/features/transaction/screen/transaction_screen.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';
import 'package:sistem_rs/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  var hospital = await Hive.openBox(HiveDbServices.boxHospital);
  if(hospital.isEmpty){
    try {
      String jsonString = await rootBundle.loadString('assets/json/hospital.json');
      List<dynamic> jsonList = jsonDecode(jsonString);
      await hospital.put(HiveDbServices.boxHospital, jsonList);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading hospital JSON: $e");
      }
    }
  }
  var room = await Hive.openBox(HiveDbServices.boxRoom);
  if(room.isEmpty){
    try {
      String jsonString = await rootBundle.loadString('assets/json/room.json');
      List<dynamic> jsonList = jsonDecode(jsonString);
      await room.put(HiveDbServices.boxRoom, jsonList);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading room JSON: $e");
      }
    }
  }

  final transaction = await Hive.openBox(HiveDbServices.boxTransaction);
  List<dynamic> rawList = transaction.get(HiveDbServices.boxTransaction, defaultValue: []);
  List<Map<dynamic, dynamic>> allTransactions = rawList.map((e) => Map<dynamic, dynamic>.from(e)).toList();
  DateTime now = DateTime.now();
  String currentMonthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  List<Map<dynamic, dynamic>> keptTransactions = allTransactions.where((item) {
    String tDate = item['transaction_date'] ?? '';
    return tDate.startsWith(currentMonthYear);
  }).toList();
  await transaction.put(HiveDbServices.boxTransaction, keptTransactions);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.white),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  List<PieChartSectionData> chartHospital = [];
  List<ChartDetail> detail = [];
  Map<String, int> hospitals = {};

  List<Hospital> allHospitals = [];
  List<Room> allRoom = [];
  
  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    hospitals = groupHospitalByCity(allHospitals);
    chartHospital.clear();
    detail.clear();

    hospitals.forEach((city, total){
      int title = total;
      String color = "";
      switch (city.toLowerCase()) {
        case "cilacap":
          color = "2A4491";
          break;
        case "banyumas":
          color = "44853B";
          break;
        case "purbalingga":
          color = "6594B1";
          break;
        default:
      }
      chartHospital.add(
        PieChartSectionData(
          value: title.toDouble(),
          title: title.toString(),
          color: Color(int.parse("0xFF$color")),
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.black,
          ),
          radius: 20,
          showTitle: false,
          badgeWidget: Text(
            "",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
      detail.add(ChartDetail(
        color: color,
        total: total,
        name: "$city ($title)",
      ));
    }); 
  }

  Map<String, int> groupHospitalByCity(List<Hospital> hospitals) {
    final Map<String, int> result = {};

    for (final hospital in hospitals) {
      result[hospital.hospitalCity!] = (result[hospital.hospitalCity] ?? 0) + 1;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    readHospitalData();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: Image.asset("assets/images/logo-text.png", width: MediaQuery.sizeOf(context).width / 2.5),
        centerTitle: true,
      ),
      body: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(
          height: MediaQuery.sizeOf(context).height - kToolbarHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 1),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    children: [
                      Text("Data Jumlah Rumah Sakit", style: TextStyle(fontWeight: FontWeight.w600),),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).width * 0.4,
                                width: MediaQuery.sizeOf(context).width * 0.4,
                                child: PieChart(
                                  PieChartData(
                                    sections: chartHospital,
                                    centerSpaceColor: Colors.white,
                                    startDegreeOffset: 90,
                                    pieTouchData: PieTouchData(
                                      enabled: false,
                                    ),
                      
                                  ),
                                  curve: Curves.easeInOut,
                                  duration: Duration(milliseconds: 1000),
                                ),
                              ),
                              Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      textScaler: TextScaler.noScaling,
                                      "Total Rumah Sakit",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                    Text(
                                      textScaler: TextScaler.noScaling,
                                      allHospitals.isNotEmpty ? allHospitals.length.toString() : "0",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "Poppins",
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          SizedBox(width: 20),
                          SizedBox(
                            height: MediaQuery.sizeOf(context).width * 0.4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: detail.map((item) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: SizedBox(
                                    width: (MediaQuery.sizeOf(context).width * 0.5 - 40),
                                    child : Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse("0xFF${item.color}")),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: EdgeInsets.only(right: 10),
                                        ),
                                        Text(
                                          textScaler: TextScaler.noScaling,
                                          "${item.name}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> HospitalScreen()));
                      },
                      child: Container(
                        height: 50,
                        width: MediaQuery.sizeOf(context).width * 0.4,
                        margin: EdgeInsets.only(left: 20),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(0, 1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/svg/hospital.svg", height: 30,),
                            SizedBox(width: 5,),
                            Text("Rumah Sakit", textScaler: TextScaler.noScaling,),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> RoomScreen()));
                      },
                      child: Container(
                        height: 50,
                        width: MediaQuery.sizeOf(context).width * 0.4,
                        margin: EdgeInsets.only(right: 20),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(0, 1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/svg/bedroom.svg", height: 30,),
                            SizedBox(width: 5,),
                            Text("Ruangan", textScaler: TextScaler.noScaling,),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> TransactionScreen()));
                  },
                  child: Center(
                    child: Container(
                      height: 50,
                      width: MediaQuery.sizeOf(context).width - 40,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 1),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset("assets/svg/bedroom-2.svg", height: 30,),
                          SizedBox(width: 5,),
                          Text("Ruangan & Tempat Tidur", textScaler: TextScaler.noScaling,),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChartDetail {
  String? color;
  String? name;
  int? total;

  ChartDetail({
    this.color,
    this.name,
    this.total,
  });
}
