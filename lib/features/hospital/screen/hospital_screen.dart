import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hive/hive.dart';
import 'package:sistem_rs/features/hospital/model/hospital_model.dart';
import 'package:sistem_rs/features/hospital/screen/create_hospital_screen.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {

  List<Hospital> allHospitals = [];
  List<Hospital> filteredHospitals = [];

  TextEditingController searchController = TextEditingController();

  final _key = Key("floatingKey");

  void readHospitalData() {
    filteredHospitals.clear();
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    filteredHospitals = allHospitals;
  }

  List<Hospital> searchHospitalsByName(String search) {
    return allHospitals.where((item) {
      final hospitalName = item.hospitalName?.toString().toLowerCase() ?? '';
      final searchLower = search.toLowerCase();
    
      return hospitalName.contains(searchLower);
    }).toList();
  }

  Future<void> deleteHospital(String id) async {
    final box = await Hive.openBox(HiveDbServices.boxHospital);
    final List<dynamic> currentList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    final updatedList = currentList.where((hospital) {
      return hospital['hospital_id'] != id;
    }).toList();
    await box.put(HiveDbServices.boxHospital, updatedList);
  }

  void downloadReport() async {
    final box = Hive.box(HiveDbServices.boxHospital);
    final rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    final List<Hospital> hospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    
    final headers = ['ID', 'Name', 'City'];
    final data = hospitals.map((hospital) {
      return [
        hospital.hospitalId?.toString() ?? '-',
        hospital.hospitalName?.toString() ?? '-',
        hospital.hospitalCity?.toString() ?? '-',
      ];
    });

    pdf.addPage(
      pw.MultiPage(build: (pw.Context context){
        return [
          pw.Header(
            level: 0,
            child: pw.Text("Data Rumah Sakit", style: pw.TextStyle(font: font, fontSize: 24)),
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
        title: Text("Daftar Rumah Sakit", textScaler: TextScaler.noScaling,),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: size.height - kToolbarHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: TextFormField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    value.isEmpty ? filteredHospitals = allHospitals : null;
                  });
                },
                decoration: InputDecoration(
                  hint: Text("Masukkan nama rumah sakit", textScaler: TextScaler.noScaling,),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        if(searchController.text.isNotEmpty){
                          filteredHospitals = searchHospitalsByName(searchController.text);
                        } else {
                          filteredHospitals = allHospitals;
                        }
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
            filteredHospitals.isEmpty ? Expanded(child: Center(child: Text("Data tidak ditemukan"))) : Expanded(
              child: ListView.builder(
                itemCount: filteredHospitals.length,
                itemBuilder: (context, index){
                  var item = filteredHospitals[index];
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateHospitalScreen(data: item)));
                      setState(() {
                        readHospitalData();
                        searchController.clear();
                      }); 
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
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
                          Text(item.hospitalId ?? "", textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, color: Colors.black54),),
                          Text(item.hospitalName ?? "", textScaler: TextScaler.noScaling),
                          Text(item.hospitalCity ?? "", textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 14, color: Colors.black54),),
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
              await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateHospitalScreen()));
              readHospitalData();
            },
            shape: const CircleBorder(),
            backgroundColor: Color(0XFF2A4491),
            foregroundColor: Color(0XFF2A4491),
            child: Icon(Icons.add_rounded, color: Colors.white,),
          ),
          FloatingActionButton(
            heroTag: null,
            onPressed: (){
              downloadReport();
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
}