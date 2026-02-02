import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/hospital/model/hospital_model.dart';
import 'package:sistem_rs/features/room/model/room_model.dart';
import 'package:sistem_rs/features/room/screen/create_room_screen.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

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
  TextEditingController findingsController = TextEditingController();

  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    readRoomData();
  }
  
  void downloadReport(String hospitalId) async {
    final box = Hive.box(HiveDbServices.boxRoom);
    final rawList = box.get(HiveDbServices.boxRoom, defaultValue: []);
    final List<Room> room = List.from(rawList).map((item) {
      return Room.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    String hospitalName = "";
    if(room.isNotEmpty){
      for (var element in allHospitals) {
        if(element.hospitalId == hospitalId){
          hospitalName = element.hospitalName ?? "";
        }
      }
    }

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    
    final headers = ['Kode Ruangan', 'Ruangan', 'Kelas'];
    final data = room.map((hospital) {
      return [
        hospital.roomId?.toString() ?? '-',
        hospital.roomName?.toString() ?? '-',
        hospital.roomClass?.toString() ?? '-',
      ];
    });

    pdf.addPage(
      pw.MultiPage(build: (pw.Context context){
        return [
          pw.Header(
            level: 0,
            child: pw.Text("Data Ruangan $hospitalName", style: pw.TextStyle(font: font, fontSize: 20)),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.normal),
            data: data.toList(),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(color: PdfColors.black)
          )
        ];
      })
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
 
  @override
  void initState() {
    readHospitalData();
    initializeDateFormatting('id_ID', null);
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
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomScreen(data: item)));
                      setState(() {
                        readRoomData();
                        searchController.clear();
                      });
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
            onPressed: () async {
              if(selectedHospitalId !=null){
                downloadReport(selectedHospitalId!);
              } else {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.warning,
                  text: "Silakan pilih rumah sakit terlebih dahulu",
                  showCancelBtn: false,
                  confirmBtnText: "Ok",
                  onConfirmBtnTap: (){
                    int count = 0;
                    Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 1);
                  }
                );
              }
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