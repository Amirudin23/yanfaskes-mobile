class Hospital {
  String? hospitalId;
  String? hospitalName;
  String? hospitalCity;

  Hospital({
    this.hospitalId,
    this.hospitalName,
    this.hospitalCity,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
    hospitalId: json["hospital_id"],
    hospitalName: json["hospital_name"],
    hospitalCity: json["hospital_city"],
  );

  Map<String, dynamic> toJson() => {
    "hospital_id": hospitalId,
    "hospital_name": hospitalName,
    "hospital_city": hospitalCity,
  };
}