class EmployeeModel {
  final int id;
  final int userId;
  final String username;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final String employeeCode;
  final String department;
  final String position;
  final DateTime? dateOfBirth;
  final DateTime hireDate;
  final double basicSalary;
  final String status;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.employeeCode,
    required this.department,
    required this.position,
    this.dateOfBirth,
    required this.hireDate,
    required this.basicSalary,
    required this.status,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'Employee',
      employeeCode: json['employeeCode'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      hireDate: json['hireDate'] != null ? DateTime.parse(json['hireDate']) : DateTime.now(),
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'employeeCode': employeeCode,
      'department': department,
      'position': position,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'hireDate': hireDate.toIso8601String(),
      'basicSalary': basicSalary,
      'status': status,
    };
  }
}
