class Room {
  String? roomId;
  String? roomName;
  String? roomClass;
  String? hospitalId;

  Room({
    this.roomId,
    this.roomName,
    this.roomClass,
    this.hospitalId,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    roomId: json["room_id"],
    roomName: json["room_name"],
    roomClass: json["room_class"],
    hospitalId: json["hospital_id"],
  );

  Map<String, dynamic> toJson() => {
    "room_id": roomId,
    "room_name": roomName,
    "room_class": roomClass,
    "hospital_id": hospitalId,
  };
}