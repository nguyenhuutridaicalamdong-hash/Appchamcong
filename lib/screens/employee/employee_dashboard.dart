import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'history_screen.dart';
import 'qr_scanner_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final UserModel user;

  const EmployeeDashboard({super.key, required this.user});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  double _workingHours = 0;
  String _todayStatus = 'Chưa chấm công';

  double? _distanceToOffice;
  bool _isLoadingLocation = false;

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
    _fetchCurrentLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _distanceToOffice = LocationService.calculateDistanceToCompany(pos.latitude, pos.longitude);
        }
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadTodayStatus() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getTodayStatus();
      setState(() {
        _isCheckedIn = res['isCheckedIn'] ?? false;
        _isCheckedOut = res['isCheckedOut'] ?? false;
        _todayStatus = res['status'] ?? 'Chưa chấm công';
        _workingHours = (res['workingHours'] as num?)?.toDouble() ?? 0.0;
        if (res['checkInTime'] != null) _checkInTime = DateTime.tryParse(res['checkInTime']);
        if (res['checkOutTime'] != null) _checkOutTime = DateTime.tryParse(res['checkOutTime']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ĐẶT LẠI (RESET) CHẤM CÔNG HÔM NAY ĐỂ TEST TIẾP
  void _confirmResetToday() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Đặt lại ca hôm nay'),
          ],
        ),
        content: const Text(
          'Bạn có muốn xóa lượt chấm công của ngày hôm nay để thực hiện lại từ đầu không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final res = await ApiService.resetTodayAttendance(employeeId: widget.user.employeeId);
              setState(() => _isLoading = false);
              if (res['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Đã đặt lại trạng thái chấm công!'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
                _loadTodayStatus();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Đặt lại thất bại!'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Đặt lại ngay'),
          ),
        ],
      ),
    );
  }

  // 1. CHECK-IN CÓ KIỂM TRA ĐỊNH VỊ GPS
  void _handleCheckInWithGps() async {
    setState(() => _isLoading = true);

    final pos = await LocationService.getCurrentLocation();
    String gpsNote = 'Check-in thủ công';

    if (pos != null) {
      final dist = LocationService.calculateDistanceToCompany(pos.latitude, pos.longitude);
      gpsNote = 'GPS: ${dist.toStringAsFixed(1)}m cách VP (Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)})';

      if (dist > LocationService.maxAllowedDistanceMeters) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: AppTheme.warning),
                SizedBox(width: 8),
                Text('Cảnh Báo Vị Trí'),
              ],
            ),
            content: Text(
              'Bạn đang cách văn phòng công ty ${dist.toStringAsFixed(0)} mét (Vượt quá bán kính 300m cho phép).\n\nBạn có muốn tiếp tục chấm công từ xa không?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tiếp tục')),
            ],
          ),
        );
        if (confirm != true) return;
        setState(() => _isLoading = true);
      }
    }

    try {
      final res = await ApiService.checkIn(
        employeeId: widget.user.employeeId,
        note: gpsNote,
      );
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['data']['message'] ?? 'Check-in GPS thành công!'),
            backgroundColor: AppTheme.accent,
          ),
        );
        _loadTodayStatus();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Check-in thất bại'), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  // 2. CHECK-IN BẰNG QUÉT MÃ QR CODE
  void _openQrScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrScannerScreen(employeeId: widget.user.employeeId)),
    );
    if (result == true) {
      _loadTodayStatus();
    }
  }

  void _handleCheckOut() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.checkOut(employeeId: widget.user.employeeId);
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['data']['message'] ?? 'Check-out thành công!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        _loadTodayStatus();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Check-out thất bại'), backgroundColor: AppTheme.error),
        );
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
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm:ss');
    final shortTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển Nhân Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử chấm công',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ApiService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTodayStatus();
          await _fetchCurrentLocation();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Thông tin nhân viên
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Xin chào,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            widget.user.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã ID: ${widget.user.employeeId ?? widget.user.userId} • ${widget.user.email}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // THANH THÔNG BÁO VỊ TRÍ GPS THỰC TẾ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _distanceToOffice != null && _distanceToOffice! <= 300
                          ? AppTheme.accent.withValues(alpha: 0.15)
                          : AppTheme.warning.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: _distanceToOffice != null && _distanceToOffice! <= 300 ? AppTheme.accent : AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Định vị GPS Văn Phòng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            _isLoadingLocation
                                ? 'Đang xác định vị trí...'
                                : (_distanceToOffice != null
                                    ? 'Cách văn phòng: ${_distanceToOffice!.toStringAsFixed(0)} mét (${_distanceToOffice! <= 300 ? "Trong bán kính" : "Ngoài bán kính"})'
                                    : 'Chưa lấy được tọa độ GPS'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _distanceToOffice != null && _distanceToOffice! <= 300 ? AppTheme.accent : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _fetchCurrentLocation,
                      tooltip: 'Cập nhật lại GPS',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Đồng hồ số
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        timeFormat.format(_currentTime),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateFormat.format(_currentTime),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Trạng thái: $_todayStatus',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Giờ vào / Giờ ra
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                                child: const Icon(Icons.login_rounded, size: 16, color: AppTheme.accent),
                              ),
                              const SizedBox(width: 8),
                              const Text('Giờ vào', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _checkInTime != null ? shortTime.format(_checkInTime!) : '--:--',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                                child: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.secondary),
                              ),
                              const SizedBox(width: 8),
                              const Text('Giờ ra', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _checkOutTime != null ? shortTime.format(_checkOutTime!) : '--:--',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // NÚT CHẤM CÔNG GPS HOẶC QUÉT QR CODE
              if (!_isCheckedIn) ...[
                // Nút Check In GPS
                InkWell(
                  onTap: _isLoading ? null : _handleCheckInWithGps,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, size: 44, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'CHECK IN',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        Text('Điểm danh vị trí GPS', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút Quét QR Code
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _openQrScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
                  label: const Text(
                    'Quét Mã QR Văn Phòng Để Check-in',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ] else if (!_isCheckedOut) ...[
                // Nút Check Out
                InkWell(
                  onTap: _isLoading ? null : _handleCheckOut,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.exit_to_app_rounded, size: 44, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'CHECK OUT',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        Text('Điểm danh ra ca', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _confirmResetToday,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Đặt lại lượt Check-in'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, size: 54, color: AppTheme.accent),
                      const SizedBox(height: 12),
                      const Text(
                        'Bạn đã hoàn thành ca làm việc hôm nay!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tổng thời gian ghi nhận: $_workingHours giờ',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF047857)),
                      ),
                      const SizedBox(height: 20),
                      // NÚT ĐẶT LẠI CHẤM CÔNG HÔM NAY (TEST DEMO)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF065F46),
                          side: const BorderSide(color: Color(0xFF059669)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirmResetToday,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Đặt lại chấm công hôm nay'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
