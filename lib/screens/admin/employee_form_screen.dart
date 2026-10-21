import 'package:flutter/material.dart';
import '../../models/employee_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EmployeeFormScreen extends StatefulWidget {
  final EmployeeModel? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _codeController;
  late TextEditingController _deptController;
  late TextEditingController _positionController;
  late TextEditingController _salaryController;

  bool _isLoading = false;
  bool get isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _fullNameController = TextEditingController(text: emp?.fullName ?? '');
    _usernameController = TextEditingController(text: emp?.username ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: emp?.phoneNumber ?? '');
    _codeController = TextEditingController(text: emp?.employeeCode ?? 'NV0002');
    _deptController = TextEditingController(text: emp?.department ?? 'Phòng Kỹ Thuật');
    _positionController = TextEditingController(text: emp?.position ?? 'Lập trình viên');
    _salaryController = TextEditingController(
      text: emp != null ? emp.basicSalary.toStringAsFixed(0) : '8000000',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _deptController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final salary = double.tryParse(_salaryController.text.trim()) ?? 0;

      if (isEditing) {
        // CẬP NHẬT NHÂN VIÊN
        final res = await ApiService.updateEmployee(
          widget.employee!.id,
          {
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'department': _deptController.text.trim(),
            'position': _positionController.text.trim(),
            'basicSalary': salary,
            'status': widget.employee!.status,
          },
        );

        setState(() => _isLoading = false);

        if (res['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật nhân viên thành công!')),
          );
          Navigator.pop(context, true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Cập nhật thất bại'), backgroundColor: AppTheme.error),
          );
        }
      } else {
        // THÊM MỚI NHÂN VIÊN
        final res = await ApiService.createEmployee({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'employeeCode': _codeController.text.trim().toUpperCase(),
          'department': _deptController.text.trim(),
          'position': _positionController.text.trim(),
          'basicSalary': salary,
          'status': 'Active',
        });

        setState(() => _isLoading = false);

        if (res['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm mới nhân viên thành công!')),
          );
          Navigator.pop(context, true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Thêm nhân viên thất bại'), backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh Sửa Nhân Viên' : 'Thêm Mới Nhân Viên'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thông tin tài khoản & cá nhân',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primary),
              ),
              const SizedBox(height: 14),

              // Họ tên
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Họ và tên *', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập email' : null,
              ),
              const SizedBox(height: 14),

              // Số điện thoại
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),

              // Nếu thêm mới thì cần Username & Password
              if (!isEditing) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Tên đăng nhập *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo *', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v!.trim().length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 12),
              const Text(
                'Thông tin công việc & lương',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primary),
              ),
              const SizedBox(height: 14),

              // Mã nhân viên
              if (!isEditing) ...[
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Mã nhân viên (VD: NV0002) *', prefixIcon: Icon(Icons.qr_code)),
                  validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập mã nhân viên' : null,
                ),
                const SizedBox(height: 14),
              ],

              // Phòng ban
              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(labelText: 'Phòng ban *', prefixIcon: Icon(Icons.apartment_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập phòng ban' : null,
              ),
              const SizedBox(height: 14),

              // Chức vụ
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Chức vụ *', prefixIcon: Icon(Icons.work_outline)),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập chức vụ' : null,
              ),
              const SizedBox(height: 14),

              // Lương cơ bản
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lương cơ bản (VNĐ) *', prefixIcon: Icon(Icons.payments_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập mức lương' : null,
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(isEditing ? 'Lưu thay đổi' : 'Tạo mới nhân viên'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
