import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sistem_rs/features/master/model/hospital_model.dart';
import 'package:sistem_rs/features/master/model/room_model.dart';
import 'package:sistem_rs/manager/hive_db_helper.dart';

class CreateRoomScreen extends StatefulWidget {
  final Room? data;
  const CreateRoomScreen({super.key, this.data});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {

  TextEditingController roomNameController = TextEditingController();
  TextEditingController roomClassController = TextEditingController();
  String? selectedHospitalId;
  List<Hospital> allHospitals = [];

  
  void readHospitalData() {
    var box = Hive.box(HiveDbServices.boxHospital);
    List<dynamic> rawList = box.get(HiveDbServices.boxHospital, defaultValue: []);
    allHospitals = List.from(rawList).map((item) {
      return Hospital.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    if(widget.data != null){
      roomNameController.text = widget.data?.roomName ?? "";
      roomClassController.text = widget.data?.roomClass ?? "";
      selectedHospitalId = widget.data?.hospitalId ?? "";
    }
  }

  Future<void> addRoom(RoomData data) async {
    final box = await Hive.openBox(HiveDbServices.boxRoom);
    List<dynamic> rawList = box.get(HiveDbServices.boxRoom, defaultValue: []);
    List<Map<dynamic, dynamic>> allRooms = List<Map<dynamic, dynamic>>.from(rawList);

    int maxSequence = 0;

    for (var room in allRooms) {
      String currentId = room['room_id'] ?? '';
      String currentHospitalId = room['hospital_id'] ?? '';

      if (currentHospitalId == data.hospitalId) {
        List<String> parts = currentId.split('-');
        
        if (parts.length == 2) {
          int? seq = int.tryParse(parts[1]);
          if (seq != null && seq > maxSequence) {
            maxSequence = seq;
          }
        }
      }
    }

    int newSequence = maxSequence + 1;
    String sequenceString = newSequence.toString().padLeft(2, '0');
    String newRoomId = "${data.hospitalId}-$sequenceString";

    final newRoom = {
      "room_id": newRoomId,
      "hospital_id": data.hospitalId,
      "room_name": data.roomName,
      "room_class": data.roomClass,
    };

    allRooms.add(newRoom);
    await box.put(HiveDbServices.boxRoom, allRooms);
    successPopup("Berhasil menyimpan data");
  }
  
  Future<void> updateRoom(RoomData data) async {
    final box = await Hive.openBox(HiveDbServices.boxRoom);
    final List<dynamic> currentList = box.get(HiveDbServices.boxRoom, defaultValue: []);
    final index = currentList.indexWhere((room) => room['room_id'] == widget.data?.roomId);

    if (index != -1) {
      final Map<dynamic, dynamic> oldData = currentList[index];

      final updatedRoom = {
        'room_id' : widget.data?.roomId ?? "",
        'room_name': data.roomName ?? oldData['room_name'],
        'room_class': data.roomClass ?? oldData['room_city'],
        'hospital_id': data.hospitalId ?? oldData['hospital_id'],
      };

      final updatedList = List<dynamic>.from(currentList);
      updatedList[index] = updatedRoom;

      await box.put(HiveDbServices.boxRoom, updatedList);
      successPopup("Berhasil mengubah data");
    } else {
      failurePopup("Gagal mengubah data");
    }
  }
  
  Future<void> deleteRoom(String id) async {
    final box = await Hive.openBox(HiveDbServices.boxRoom);
    final List<dynamic> currentList = box.get(HiveDbServices.boxRoom, defaultValue: []);

    final updatedList = currentList.where((room) {
      return room['room_id'] != id;
    }).toList();

    if (currentList.length != updatedList.length) {
      await box.put(HiveDbServices.boxRoom, updatedList);
      successPopup("Berhasil menghapus data");
    } else {
      failurePopup("Gagal menghapus data");
    }
  }

  @override
  void initState() {
    super.initState();
    readHospitalData();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Ruangan", textScaler: TextScaler.noScaling,),
        scrolledUnderElevation: 0,
        actions: [
          widget.data !=null ? IconButton(
            onPressed: () async {
              await deleteRoom(widget.data?.roomId ?? "");
            },
            icon: Icon(Icons.delete_forever_rounded)
          ) : Container()
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        height: size.height - kToolbarHeight - 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama Ruangan", textScaler: TextScaler.noScaling,),
              SizedBox(height: 10),
              TextFormField(
                controller: roomNameController,
                decoration: InputDecoration(
                  hint: Text("Masukkan nama ruangan", textScaler: TextScaler.noScaling,),
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
              Text("Kelas", textScaler: TextScaler.noScaling,),
              SizedBox(height: 10),
              TextFormField(
                controller: roomClassController,
                decoration: InputDecoration(
                  hint: Text("Masukkan kelas ruangan", textScaler: TextScaler.noScaling,),
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
              Text("Rumah Sakit", textScaler: TextScaler.noScaling,),
              SizedBox(height: 10),
              DropdownButtonFormField(
                onChanged: (value){
                  setState(() {
                    if(value!=null){
                      selectedHospitalId = value;
                    }  
                  });
                },
                items: allHospitals.map((item) => DropdownMenuItem(value: item.hospitalId, child: Text(item.hospitalName ?? "", textScaler: TextScaler.noScaling,))).toList(),
                initialValue: selectedHospitalId,
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
              Container(
                margin: EdgeInsets.only(top: 25),
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    final room = RoomData(
                      hospitalId: selectedHospitalId,
                      roomName: roomNameController.text,
                      roomClass: roomClassController.text,
                    );
                    widget.data != null ? await updateRoom(room) : await addRoom(room);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0XFF2A4491),
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
                      fontWeight: FontWeight.w600,
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

class RoomData {
  String? hospitalId;
  String? roomId;
  String? roomName;
  String? roomClass;

  RoomData({
    this.hospitalId,
    this.roomId,
    this.roomName,
    this.roomClass,
  });
}