import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/hospital/model/hospital_model.dart';
import 'package:sistem_rs/features/room/model/room_model.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CreateTransactionScreen extends StatefulWidget {
  final String? hospitalId;
  final List<Room>? allRoom;
  const CreateTransactionScreen({super.key, this.hospitalId, this.allRoom});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {

  List<Room> filteredRoom = [];
  List<Hospital> allHospitals = [];

  TextEditingController searchController = TextEditingController();

  TextEditingController roomCountController = TextEditingController();
  TextEditingController bedCountController = TextEditingController();
  TextEditingController findingsController = TextEditingController();

  TextEditingController dateController = TextEditingController();

  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  List<Room> searchRoomByName(String search) {
    if(search.isEmpty){
      filteredRoom = widget.allRoom!.where((room) => room.hospitalId == widget.hospitalId).toList();
    } else {
      filteredRoom = widget.allRoom!.where((room) {
        final isSameHospital = room.hospitalId == widget.hospitalId;
        final nameMatches = room.roomName?.toLowerCase().contains(search.toLowerCase()) ?? false;

        return isSameHospital && nameMatches;
      }).toList();
    }
  
    return filteredRoom;
  }
  
  Future<void> addTransaction({
    required String roomCount,
    required String bedCount,
    required String hospitalId,
    required String hospitalName,
    required String roomId,
    required String roomName,
    required String roomClass,
    required String findings,
    }) async {
    final box = await Hive.openBox(HiveDbServices.boxTransaction);
    final List<dynamic> currentList = box.get(HiveDbServices.boxTransaction, defaultValue: []);

    var uuid = Uuid();
    String transactionId = uuid.v4();

    currentList.removeWhere((item){
      return item['room_id'] == roomId;
    });

    final newTransaction = {
      "transaction_id": transactionId,
      "transaction_date": DateFormat("yyyy-MM-dd").format(DateTime.now()),
      "room_count": roomCount,
      "bed_count": bedCount,
      "hospital_name": hospitalName,
      "room_id": roomId,
      "room_name": roomName,
      "room_class": roomClass,
      "hospital_id": hospitalId,
      "findings": findings,
    };
    final  updatedList = List<dynamic>.from(currentList);
    updatedList.add(newTransaction);
    await box.put(HiveDbServices.boxTransaction, updatedList);
    successPopup("Berhasil menyimpan data");
    setState(() {
      roomCountController.clear();
      bedCountController.clear();
      findingsController.clear();
    });
  }

  Future<void> generateFilteredPdf() async {
    final box = await Hive.openBox(HiveDbServices.boxTransaction);
    final List<dynamic> rawData = box.get(HiveDbServices.boxTransaction, defaultValue: []);
    String hospitalId = "";
    String hospitalName = "";

    if(rawData.isEmpty){
      if(mounted){
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          text: "Tidak ada transaksi pada $hospitalName bulan ini",
          showCancelBtn: false,
          confirmBtnText: "Ok",
          onConfirmBtnTap: (){
            int count = 0;
            Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 1);
          }
        );
      }
    } else {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();

      final filteredData = rawData.where((item) {
        return item['hospital_id'] == widget.hospitalId;
      }).toList();

      if(filteredData.isEmpty){
        if(mounted){
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text: "Tidak ada transaksi pada $hospitalName bulan ini",
            showCancelBtn: false,
            confirmBtnText: "Ok",
            onConfirmBtnTap: (){
              int count = 0;
              Navigator.of(context, rootNavigator: true).popUntil((_) => count++ >= 1);
            }
          );
        }
      } else {
        filteredData.sort((a, b) {
          int cmp = (a['hospital_name'] ?? '').compareTo(b['hospital_name'] ?? '');
          if (cmp != 0) return cmp;
          return (a['room_name'] ?? '').compareTo(b['room_name'] ?? '');
        });

        List<List<String>> tableData = [];

        for (var item in filteredData) {
          hospitalName = item['hospital_name'] ?? '';
          hospitalId = item['hospital_id']?.toString() ?? '';
          final String roomName = item['room_name'] ?? '-';
          final String roomClass = item['room_class'] ?? '-';
          final String findings = item['findings'] ?? '-';
          
          final int roomCount = int.tryParse(item['room_count'].toString()) ?? 0;
          final int bedsCount = int.tryParse(item['bed_count'].toString()) ?? 0;

          final int totalBeds = roomCount * bedsCount;

          tableData.add([
            roomName,
            roomClass,
            roomCount.toString(),
            bedsCount.toString(),
            totalBeds.toString(),
            findings
          ]);
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Laporan Pra-Rekredensialing", style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Tanggal : ${DateFormat("d MMMM yyyy", "id_ID").format(DateTime.now())}", style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.Text("$hospitalId - $hospitalName", style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.SizedBox(height: 20),
                  ]
                ),
                
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  headers: [
                    'Nama Ruangan',
                    'Kelas Ruangan',
                    'Jumlah Ruangan',
                    'Tempat Tidur\nPer Ruangan',
                    'Total Tempat Tidur',
                    'Temuan'
                  ],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 10),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  headerPadding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10)
                ),
              ];
            },
          ),
        );

        await Printing.layoutPdf(onLayout: (format) => pdf.save());
      }

    }
  }

  @override
  void initState() {
    filteredRoom = widget.allRoom!.where((room) => room.hospitalId == widget.hospitalId).toList();
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
        actions: [
          IconButton(
            onPressed: () {
              generateFilteredPdf();
            },
            icon: Icon(Icons.file_download_outlined)
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: size.height - kToolbarHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: TextFormField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    value.isEmpty ? filteredRoom = searchRoomByName(searchController.text) : null;
                  });
                },
                decoration: InputDecoration(
                  hint: Text("Masukkan nama ruangan", textScaler: TextScaler.noScaling,),
                  suffixIcon: IconButton(
                    onPressed: (){
                      setState(() {
                        filteredRoom = searchRoomByName(searchController.text);
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
                                      Text("Ruangan ${item.roomName}", textScaler: TextScaler.noScaling,),
                                      Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              content: Container(
                                height: 380,
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
                                    SizedBox(height: 20),
                                    Text("Temuan", textScaler: TextScaler.noScaling,),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: findingsController,
                                      decoration: InputDecoration(
                                        hint: Text("Masukkan temuan", textScaler: TextScaler.noScaling,),
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
                          addTransaction(
                            roomCount : roomCountController.text,
                            bedCount: bedCountController.text,
                            hospitalName: hospitalName,
                            hospitalId: item.hospitalId ?? "",
                            roomId: item.roomId ?? "",
                            roomName: item.roomName ?? "",
                            roomClass: item.roomClass ?? "",
                            findings: findingsController.text,
                          );
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