import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/master/model/hospital_model.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';

class CreateTransactionScreen extends StatefulWidget {
  final Hospital? data;
  const CreateTransactionScreen({super.key, this.data});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {

  @override
  void initState() {
    super.initState();
    if(widget.data != null){
      hospitalIdController.text = widget.data?.hospitalId ?? "";
      hospitalNameController.text = widget.data?.hospitalName ?? "";
      selectedHospitalCity = widget.data?.hospitalCity ?? "";
    }
  }    

  TextEditingController hospitalNameController = TextEditingController();
  TextEditingController hospitalIdController = TextEditingController();
  String? selectedHospitalCity;

  Future<void> addHospital(HospitalData hospital) async {
    final box = await Hive.openBox(HiveDbServices.boxHospital);
    final List<dynamic> currentList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    final newHospital = {
      "hospital_id": hospital.hospitalId,
      "hospital_name": hospital.hospitalName,
      "hospital_city": hospital.hospitalCity
    };
    final  updatedList = List<dynamic>.from(currentList);
    updatedList.add(newHospital);
    await box.put(HiveDbServices.boxHospital, updatedList);
    successPopup("Berhasil menyimpan data");
  }
  
  Future<void> deleteHospital(String id) async {
    final box = await Hive.openBox(HiveDbServices.boxHospital);
    final List<dynamic> currentList = box.get(HiveDbServices.boxHospital, defaultValue: []);

    final updatedList = currentList.where((hospital) {
      return hospital['hospital_id'] != id;
    }).toList();

    if (currentList.length != updatedList.length) {
      await box.put(HiveDbServices.boxHospital, updatedList);
      successPopup("Berhasil menghapus data");
    } else {
      failurePopup("Gagal menghapus data");
    }
  }

  
  Future<void> updateHospital(HospitalData data) async {
    final box = await Hive.openBox(HiveDbServices.boxHospital);
    final List<dynamic> currentList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    final index = currentList.indexWhere((hospital) => hospital['hospital_id'] == data.hospitalId);

    if (index != -1) {
      final Map<dynamic, dynamic> oldData = currentList[index];

      final updatedHospital = {
        'hospital_id': data.hospitalId,
        'hospital_name': data.hospitalName ?? oldData['hospital_name'],
        'hospital_city': data.hospitalCity ?? oldData['hospital_city'],
      };

      final updatedList = List<dynamic>.from(currentList);
      updatedList[index] = updatedHospital;

      await box.put(HiveDbServices.boxHospital, updatedList);
      successPopup("Berhasil mengubah data");
    } else {
      failurePopup("text");
    }
  }

  
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Data Transaksi", textScaler: TextScaler.noScaling,),
        scrolledUnderElevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        height: size.height - kToolbarHeight - 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Jumlah Kamar", textScaler: TextScaler.noScaling,),
              SizedBox(height: 10),
              TextFormField(
                controller: hospitalIdController,
                enabled: widget.data != null ? false : true,
                decoration: InputDecoration(
                  hint: Text("Masukkan jumlah kamar", textScaler: TextScaler.noScaling,),
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
                controller: hospitalNameController,
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
              Text("Kota Rumah Sakit", textScaler: TextScaler.noScaling,),
              Container(
                margin: EdgeInsets.only(top: 25),
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    // final hospital = HospitalData(
                    //   hospitalId: hospitalIdController.text,
                    //   hospitalName: hospitalNameController.text,
                    //   hospitalCity: selectedHospitalCity,
                    // );
                    // widget.data != null ? await updateHospital(hospital) : await addHospital(hospital);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(120, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text(
                   widget.data != null ? "Ubah" : "Simpan",
                   textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      fontFamily: "Poppins",
                    ),
                  )
                ),
              )
            ],
          ),
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