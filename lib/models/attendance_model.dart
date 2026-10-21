class AttendanceModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final double workingHours;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.workingHours,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      department: json['department'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      checkInTime: json['checkInTime'] != null ? DateTime.tryParse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.tryParse(json['checkOutTime']) : null,
      status: json['status'] ?? 'Chưa chấm công',
      workingHours: (json['workingHours'] as num?)?.toDouble() ?? 0.0,
      note: json['note'],
    );
  }
}

class AttendanceReportModel {
  final int totalAttendances;
  final int onTimeCount;
  final int lateCount;
  final double totalWorkingHours;
  final List<AttendanceModel> details;

  AttendanceReportModel({
    required this.totalAttendances,
    required this.onTimeCount,
    required this.lateCount,
    required this.totalWorkingHours,
    required this.details,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['details'] as List? ?? [];
    return AttendanceReportModel(
      totalAttendances: json['totalAttendances'] ?? 0,
      onTimeCount: json['onTimeCount'] ?? 0,
      lateCount: json['lateCount'] ?? 0,
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
      details: rawList.map((e) => AttendanceModel.fromJson(e)).toList(),
    );
  }
}
