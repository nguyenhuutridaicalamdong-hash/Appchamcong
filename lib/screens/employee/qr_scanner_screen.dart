import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  final int? employeeId;

  const QrScannerScreen({super.key, this.employeeId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isProcessing = true);
        _controller.stop();

        // Kiểm tra mã QR hợp lệ của công ty
        if (code.contains('NGUYENHUUTRI')) {
          _performCheckIn('Quét QR thành công: Mã bảo mật $code');
        } else {
          _showInvalidDialog(code);
        }
        break;
      }
    }
  }

  void _performCheckIn(String note) async {
    try {
      final res = await ApiService.checkIn(
        employeeId: widget.employeeId,
        note: note,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                SizedBox(width: 8),
                Text('Điểm danh thành công!'),
              ],
            ),
            content: Text(res['data']['message'] ?? 'Bạn đã điểm danh bằng QR Code thành công.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Điểm danh thất bại'), backgroundColor: AppTheme.error),
        );
        setState(() => _isProcessing = false);
        _controller.start();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  void _showInvalidDialog(String rawCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mã QR không hợp lệ'),
        content: Text('Mã "$rawCode" không phải là mã chấm công của Công ty Nguyễn Hữu Trí.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              _controller.start();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Mã QR Chấm Công'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Khung ngắm quét mã QR
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Chỉ dẫn bên dưới
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Hướng camera về phía Bảng Mã QR của văn phòng để tự động điểm danh vào ca',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
