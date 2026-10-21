import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  AttendanceReportModel? _report;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final rep = await ApiService.getReport(
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _report = rep;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải báo cáo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // PHƯƠNG ÁN 2: ADMIN XÓA / ĐẶT LẠI LƯỢT CHẤM CÔNG CỦA NHÂN VIÊN
  void _confirmDeleteAttendance(AttendanceModel item) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Xóa lượt chấm công'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa lượt chấm công ngày ${dateFormat.format(item.date)} của nhân viên ${item.employeeName}?\n\nSau khi xóa, nhân viên có thể chấm công lại ca ngày này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.deleteAttendance(item.id);
              if (res['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Đã xóa lượt chấm công thành công!'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
                _loadReport();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Xóa thất bại!'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bộ chọn Tháng & Năm
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            const Text('Thời gian:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _selectedMonth,
                              items: List.generate(12, (i) => i + 1)
                                  .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMonth = val);
                                  _loadReport();
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _selectedYear,
                              items: [2025, 2026, 2027]
                                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedYear = val);
                                  _loadReport();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thống kê tổng hợp (KPI Cards)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Tổng lượt công',
                            '${_report?.totalAttendances ?? 0}',
                            Icons.how_to_reg_rounded,
                            AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Đúng giờ',
                            '${_report?.onTimeCount ?? 0}',
                            Icons.timer_outlined,
                            AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Đi muộn',
                            '${_report?.lateCount ?? 0}',
                            Icons.alarm_off_rounded,
                            AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Tổng giờ làm',
                            '${_report?.totalWorkingHours ?? 0}h',
                            Icons.schedule_rounded,
                            AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Danh sách chi tiết lượt chấm công
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chi tiết chấm công nhân viên',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_report?.details.length ?? 0} bản ghi',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_report == null || _report!.details.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Không có dữ liệu chấm công trong tháng này',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _report!.details.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item = _report!.details[i];
                          final isLate = item.status == 'Đi muộn';

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isLate
                                    ? AppTheme.warning.withValues(alpha: 0.15)
                                    : AppTheme.accent.withValues(alpha: 0.15),
                                child: Icon(
                                  isLate ? Icons.access_time_filled : Icons.check_circle_rounded,
                                  color: isLate ? AppTheme.warning : AppTheme.accent,
                                ),
                              ),
                              title: Text(
                                item.employeeName.isNotEmpty ? item.employeeName : 'Mã NV: ${item.employeeCode}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Ngày: ${dateFormat.format(item.date)}\nVào: ${item.checkInTime != null ? timeFormat.format(item.checkInTime!) : '--'} | Ra: ${item.checkOutTime != null ? timeFormat.format(item.checkOutTime!) : '--'}',
                                style: const TextStyle(fontSize: 12, height: 1.3),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isLate
                                              ? AppTheme.warning.withValues(alpha: 0.15)
                                              : AppTheme.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(
                                            color: isLate ? AppTheme.warning : AppTheme.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.workingHours}h làm',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  // NÚT XÓA / RESET LƯỢT CHẤM CÔNG DÀNH CHO ADMIN
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                                    tooltip: 'Xóa để đặt lại lượt chấm công',
                                    onPressed: () => _confirmDeleteAttendance(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
