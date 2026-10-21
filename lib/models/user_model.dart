class UserModel {
  final int userId;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final int? employeeId;
  final String? token;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.employeeId,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      userId: json['userId'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'Employee',
      employeeId: json['employeeId'],
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'employeeId': employeeId,
      'token': token,
    };
  }
}
