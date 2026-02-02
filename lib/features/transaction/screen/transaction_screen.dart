import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/hospital/model/hospital_model.dart';
import 'package:sistem_rs/features/master/model/room_model.dart';
import 'package:sistem_rs/features/transaction/screen/create_transaction_screen.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {

  @override
  void initState() {
    super.initState();
    readHospitalData();
  }

  List<Room> allRoom = [];
  List<Room> filteredRoom = [];

  TextEditingController roomCountController = TextEditingController();
  TextEditingController bedCountController = TextEditingController();
  TextEditingController findingsController = TextEditingController();

  TextEditingController dateController = TextEditingController();

  List<HospitalRoomCount> roomPerHospital = [];
  List<HospitalRoomCount> roomCilacap = [];
  List<HospitalRoomCount> roomBanyumas = [];
  List<HospitalRoomCount> roomPurbalingga = [];

  List<Hospital> allHospitals = [];
  
  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    readRoomData();
  }

  
  void readRoomData() {
    var box = Hive.box(HiveDbServices.boxRoom);
    List<dynamic> rawList = box.get(HiveDbServices.boxRoom, defaultValue: []);

    allRoom = List.from(rawList).map((item) {
      return Room.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    allRoom.sort((a, b) {
      int cmp = a.hospitalId!.compareTo(b.hospitalId!);
      return cmp != 0 ? cmp : a.roomId!.compareTo(b.roomId!);
    });

    roomPerHospital = countRoomsPerHospital(allHospitals, allRoom);
    for (var item in roomPerHospital) {
      switch (item.city.toLowerCase()) {
        case "cilacap":
          roomCilacap.add(item);
          break;
        case "banyumas":
          roomBanyumas.add(item);
          break;
        case "purbalingga":
          roomPurbalingga.add(item);
          break;
        default:
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          height: size.height,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  labelColor: Color(0XFF2A4491),
                  tabs: [
                    Tab(text: "Cilacap"),
                    Tab(text: "Banyumas"),
                    Tab(text: "Purbalingga"),
                  ],
                  indicatorColor: Color(0XFF2A4491),
                  unselectedLabelColor: Colors.black87,
                  labelStyle: TextStyle(fontWeight: FontWeight.w500),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
                  textScaler: TextScaler.noScaling,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
                SizedBox(
                  height: size.height - kToolbarHeight,
                  child: TabBarView(
                    children: [
                      roomCilacap.isNotEmpty ? roomWidget(roomCilacap) : Center(child: Text("Tidak ada data", textScaler: TextScaler.noScaling,),),
                      roomBanyumas.isNotEmpty ? roomWidget(roomBanyumas) : Center(child: Text("Tidak ada data", textScaler: TextScaler.noScaling,),),
                      roomPurbalingga.isNotEmpty ? roomWidget(roomPurbalingga) : Center(child: Text("Tidak ada data", textScaler: TextScaler.noScaling,),),
                    ]
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget roomWidget(List<HospitalRoomCount> data){
    var size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          var item = data[index];
          return InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTransactionScreen(hospitalId: item.id, allRoom: allRoom)));
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.id, textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, color: Colors.black54),),
                      SizedBox(
                        width: size.width - 90,
                        child: Text(
                          item.name,
                          textScaler: TextScaler.noScaling,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      ),
                      Text("Jumlah Ruangan : ${item.totalRoom}", textScaler: TextScaler.noScaling, style: TextStyle(fontWeight: FontWeight.w500),),
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.black,),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  List<HospitalRoomCount> countRoomsPerHospital(
    List<Hospital> allHospitals, 
    List<Room> allRooms
  ) {
    Map<String, int> roomCounts = {};

    for (var room in allRooms) {
      String hospitalId = room.hospitalId!;
      roomCounts[hospitalId] = (roomCounts[hospitalId] ?? 0) + 1;
    }

    List<HospitalRoomCount> results = [];

    for (var hospital in allHospitals) {
      String hospitalId = hospital.hospitalId!;
      int count = roomCounts[hospitalId] ?? 0;

      results.add(HospitalRoomCount(
        id: hospitalId,
        name: hospital.hospitalName!,
        city: hospital.hospitalCity!,
        totalRoom: count,
      ));
    }

    return results;
  }

  Future<dynamic> successPopup(String text){
    return QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: text,
      showCancelBtn: false,
      confirmBtnText: "Ok",
      onConfirmBtnTap: (){
        int count = 0;
        Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 2);
      }
    );
  }

  Future<dynamic> failurePopup(String text){
    return QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      text: text,
      showCancelBtn: false,
      confirmBtnText: "Ok",
      onConfirmBtnTap: (){
        int count = 0;
        Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 1);
      }
    );
  }
}

class HospitalData {
  String? hospitalId;
  String? hospitalName;
  String? hospitalCity;

  HospitalData({
    this.hospitalId,
    this.hospitalName,
    this.hospitalCity,
  });
}

class HospitalRoomCount {
  final String id;
  final String name;
  final String city;
  final int totalRoom;

  HospitalRoomCount({
    required this.id, 
    required this.name, 
    required this.city, 
    required this.totalRoom
  });
}