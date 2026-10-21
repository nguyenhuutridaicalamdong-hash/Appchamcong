import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceModel> _list = [];
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.getMyHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _list = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Chấm Công Cá Nhân')),
      body: Column(
        children: [
          // Lọc theo Tháng/Năm
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Lọc theo:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m, child: Text('Tháng $m')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _loadHistory();
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
                      _loadHistory();
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có lịch sử chấm công trong tháng này',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final item = _list[i];
                        final isLate = item.status == 'Đi muộn';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(item.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLate
                                            ? AppTheme.warning.withValues(
                                                alpha: 0.15,
                                              )
                                            : AppTheme.accent.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          color: isLate
                                              ? AppTheme.warning
                                              : AppTheme.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Vào: ${item.checkInTime != null ? timeFormat.format(item.checkInTime!) : '--:--'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Ra: ${item.checkOutTime != null ? timeFormat.format(item.checkOutTime!) : '--:--'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${item.workingHours}h làm',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
