import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hive/hive.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/master/model/hospital_model.dart';
import 'package:sistem_rs/features/master/model/room_model.dart';
import 'package:sistem_rs/features/master/screen/create_room_screen.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';
import 'package:uuid/uuid.dart';

class RoomScreen extends StatefulWidget {
  final bool? isTransaction;
  const RoomScreen({super.key, this.isTransaction});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {

  final _key = Key("floatingKey");

  List<Room> allRoom = [];
  List<Room> filteredRoom = [];
  
  List<Hospital> allHospitals = [];
  String? selectedHospitalId;

  TextEditingController searchController = TextEditingController();

  TextEditingController roomCountController = TextEditingController();
  TextEditingController bedCountController = TextEditingController();

  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    readRoomData();
  }

  List<Hospital> searchHospitalsByCity(String search) {
    return allHospitals.where((item) {
      final hospitalCity = item.hospitalCity?.toString().toLowerCase() ?? '';
      final searchLower = search.toLowerCase();
    
      return hospitalCity.contains(searchLower);
    }).toList();
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

    filteredRoom = allRoom;
  }

  List<Room> searchRoomByHospitalAndName(String search, String? hospitalId) {
    if(hospitalId != null && hospitalId.isNotEmpty){

      filteredRoom = allRoom.where((room) {
        final isSameHospital = room.hospitalId == hospitalId;
        final nameMatches = room.roomName?.toLowerCase().contains(search.toLowerCase()) ?? false;

        return isSameHospital && nameMatches;
      }).toList();

      return filteredRoom;
    } else {
      filteredRoom =  allRoom.where((room) { 
        return room.roomName?.toLowerCase().contains(search.toLowerCase()) ?? false;
      }).toList();

      return filteredRoom;
    }
  }
  
  Future<void> addTransaction(String roomCount, String bedCount) async {
    final box = await Hive.openBox(HiveDbServices.boxTransaction);
    final List<dynamic> currentList = box.get(HiveDbServices.boxTransaction, defaultValue: []);

    var uuid = Uuid();
    String transactionId = uuid.v4();

    final newTransaction = {
      "transaction_id": transactionId,
      "room_count": roomCount,
      "bed_count": bedCount
    };
    final  updatedList = List<dynamic>.from(currentList);
    updatedList.add(newTransaction);
    await box.put(HiveDbServices.boxTransaction, updatedList);
    successPopup("Berhasil menyimpan data");
  }

  @override
  void initState() {
    readHospitalData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Daftar Ruangan", textScaler: TextScaler.noScaling,),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: size.height - kToolbarHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            DropdownButtonFormField(
              onChanged: (value){
                setState(() {
                  if(value!=null){
                    selectedHospitalId = value;
                    searchRoomByHospitalAndName(searchController.text, selectedHospitalId);
                  }
                });
              },
              items: allHospitals.map((item) => DropdownMenuItem(value: item.hospitalId, child: Text(item.hospitalName ?? "", textScaler: TextScaler.noScaling,))).toList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black26, width: 1.5)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black26, width: 1.5)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black26, width: 1.5)
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: TextFormField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    value.isEmpty ? filteredRoom = searchRoomByHospitalAndName(searchController.text, selectedHospitalId) : null;
                  });
                },
                decoration: InputDecoration(
                  hint: Text("Masukkan nama ruangan", textScaler: TextScaler.noScaling,),
                  suffixIcon: IconButton(
                    onPressed: (){
                      setState(() {
                        filteredRoom = searchRoomByHospitalAndName(searchController.text, selectedHospitalId);
                      });
                    },
                    icon: Icon(Icons.search),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black26, width: 1.5)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black26, width: 1.5)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black26, width: 1.5)
                  ),
                ),
              ),
            ),
            filteredRoom.isEmpty ? Expanded(child: Center(child: Text("Data tidak ditemukan"))) : Expanded(
              child: ListView.builder(
                itemCount: filteredRoom.length,
                itemBuilder: (context, index){
                  var item = filteredRoom[index];
                  String hospitalName = "";
                  for (var element in allHospitals) {
                    if(element.hospitalId == item.hospitalId){
                      hospitalName = element.hospitalName ?? "";
                    }
                  }
                  return InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      if(widget.isTransaction != null){
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTransactionScreen()));
                        var result = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return StatefulBuilder(builder: (context, setState) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.white,
                                elevation: 0,
                                titlePadding: const EdgeInsets.all(0),
                                titleTextStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                title: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Color(0XFF2A4491),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Transaksi ${item.roomName}", textScaler: TextScaler.noScaling,),
                                        Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                content: Container(
                                  height: 250,
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Jumlah ruangan", textScaler: TextScaler.noScaling,),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        controller: roomCountController,
                                        decoration: InputDecoration(
                                          hint: Text("Masukkan jumlah ruangan", textScaler: TextScaler.noScaling,),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text("Jumlah Tempat Tidur", textScaler: TextScaler.noScaling,),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        controller: bedCountController,
                                        decoration: InputDecoration(
                                          hint: Text("Masukkan jumlah tempat tidur", textScaler: TextScaler.noScaling,),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.black26, width: 1.5)
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              child: Container(
                                                height: 40,
                                                width: (size.width / 4) - 10,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: Color(0xffD9D9D9),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Batalkan",
                                                  textScaler: TextScaler.noScaling,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(context, true);
                                              },
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              child: Container(
                                                height: 40,
                                                width: (size.width / 3) - 10,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: Color(0XFF2A4491),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Simpan",
                                                      textScaler: TextScaler.noScaling,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                        if(result != null){
                          setState(() {
                            addTransaction(roomCountController.text, bedCountController.text);
                          });
                        }           
                      } else {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomScreen(data: item)));
                        setState(() {
                          readRoomData();
                          searchController.clear();
                        });
                      }
                    },
                    child: Container(
                      width: size.width - 50,
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 10, left: 5, right: 5, top: 5),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item.roomId ?? ""} - $hospitalName", textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, color: Colors.black54),),
                          Text(item.roomName ?? "", textScaler: TextScaler.noScaling),
                          Text(item.roomClass ?? "", textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 14, color: Colors.black54),),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ExpandableFab(
        key: _key,
        type: ExpandableFabType.up,
        distance: 70,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.menu_rounded, color: Colors.white),
          fabSize: ExpandableFabSize.regular,
          shape: const CircleBorder(),
          backgroundColor: Color(0XFF2A4491),
          foregroundColor: Colors.black
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.close_rounded, color: Colors.white),
          fabSize: ExpandableFabSize.regular,
          shape: const CircleBorder(),
          backgroundColor: Color(0XFF2A4491),
          foregroundColor: Colors.black
        ),
        children: [
          FloatingActionButton(
            heroTag: null,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomScreen()));
              setState(() {
                readRoomData();
              });
            },
            shape: const CircleBorder(),
            backgroundColor: Color(0XFF2A4491),
            foregroundColor: Color(0XFF2A4491),
            child: Icon(Icons.add_rounded, color: Colors.white,),
          ),
          FloatingActionButton(
            heroTag: null,
            onPressed: (){
              // downloadReport();
            },
            shape: const CircleBorder(),
            backgroundColor: Color(0XFF2A4491),
            foregroundColor: Color(0XFF2A4491),
            child: Icon(Icons.file_download_outlined, color: Colors.white,),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
    );
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
        Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 1);
      }
    );
  }
}