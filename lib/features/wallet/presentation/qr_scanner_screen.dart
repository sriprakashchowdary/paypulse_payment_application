import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Premium QR Scanner Screen — live camera + upload from gallery.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _isAnalyzingImage = false;
  late AnimationController _scanLineController;
  final bool _isNative = !kIsWeb;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (_isNative) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ── Live Camera QR Detect ──────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _processQrValue(barcode!.rawValue!);
  }

  // ── Upload QR Image from Gallery ────────────────────────────────

  Future<void> _pickImageAndScan() async {
    if (_isAnalyzingImage) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isAnalyzingImage = true);
      HapticFeedback.lightImpact();

      if (_isNative && _controller != null) {
        // Use mobile_scanner's built-in image analysis
        final result = await _controller!.analyzeImage(pickedFile.path);
        setState(() => _isAnalyzingImage = false);

        if (result != null) {
          final barcode = result.barcodes.firstOrNull;
          if (barcode?.rawValue != null) {
            _processQrValue(barcode!.rawValue!);
          } else {
            if (mounted) {
              _showError('No QR code found in the selected image');
            }
          }
        } else {
          if (mounted) {
            _showError('Could not read the selected image');
          }
        }
      } else {
        // Web fallback
        setState(() => _isAnalyzingImage = false);
        if (mounted) {
          _showManualEntrySheet();
        }
      }
    } catch (e) {
      setState(() => _isAnalyzingImage = false);
      if (mounted) {
        _showError('Failed to pick image: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  void _processQrValue(String rawValue) {
    if (_hasScanned) return;

    if (rawValue.startsWith('paypulse://send?')) {
      setState(() => _hasScanned = true);
      HapticFeedback.heavyImpact();
      _controller?.stop();
      _handlePayPulseQr(rawValue);
    } else {
      HapticFeedback.vibrate();
      if (mounted) _showError('Not a valid PayPulse QR code');
    }
  }

  void _handlePayPulseQr(String rawValue) {
    final uri = Uri.tryParse(rawValue.replaceFirst('paypulse://', 'https://'));
    if (uri == null) {
      _showError('Invalid QR code format');
      setState(() => _hasScanned = false);
      _controller?.start();
      return;
    }
    final email = uri.queryParameters['email'] ?? '';
    final name = uri.queryParameters['name'] ?? '';
    if (email.isEmpty) {
      _showError('QR code missing recipient email');
      setState(() => _hasScanned = false);
      _controller?.start();
      return;
    }
    _showSuccessSheet(email, name);
  }

  void _showSuccessSheet(String email, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _SuccessSheet(
        email: email,
        name: name,
        isDark: isDark,
        onSend: () {
          Navigator.of(ctx).pop();
          context.push(
            '/send-money?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}',
          );
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          setState(() => _hasScanned = false);
          _controller?.start();
        },
      ),
    );
  }

  void _showManualEntrySheet() {
    final emailCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter Recipient Email',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QR image scanning is not available on Web.\nEnter the PayPulse email manually.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'user@paypulse.network',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.textMuted),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: isDark ? Colors.white38 : AppColors.textMuted),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty || !email.contains('@')) return;
                    Navigator.of(ctx).pop();
                    context.push(
                        '/send-money?email=${Uri.encodeComponent(email)}');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Continue to Send',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Always light for Camera UI
      child: Scaffold(
        backgroundColor: Colors.black, // Camera always has black BG
        body: Stack(
          children: [
            // Camera / placeholder background
            if (_isNative && _controller != null)
              MobileScanner(controller: _controller!, onDetect: _onDetect)
            else
              _buildWebPlaceholder(),

            // Semi-transparent dark overlay (outside scanner frame)
            if (_isNative) _buildCropOverlay(),

            // All overlay UI
            _buildOverlayUi(),
          ],
        ),
      ),
    );
  }

  // ── Dark crop overlay (darken outside the scan frame) ─────────

  Widget _buildCropOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const frameSize = 260.0;
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2;
        final left = cx - frameSize / 2;
        final top = cy - frameSize / 2;

        return Stack(
          children: [
            Positioned(
                top: 0, left: 0, right: 0, height: top, child: _darkOverlay()),
            Positioned(
                top: top + frameSize,
                left: 0,
                right: 0,
                bottom: 0,
                child: _darkOverlay()),
            Positioned(
                top: top,
                left: 0,
                width: left,
                height: frameSize,
                child: _darkOverlay()),
            Positioned(
                top: top,
                left: left + frameSize,
                right: 0,
                height: frameSize,
                child: _darkOverlay()),
          ],
        );
      },
    );
  }

  Widget _darkOverlay() =>
      Container(color: Colors.black.withValues(alpha: 0.62));

  // ── Web Placeholder ────────────────────────────────────────────

  Widget _buildWebPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white30,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Camera on Web',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the "Upload QR Image" button\nbelow to scan from your gallery.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Overlay UI ────────────────────────────────────────────

  Widget _buildOverlayUi() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          _buildTopBar().animate().fadeIn().slideY(begin: -0.2),

          const Spacer(),

          // Scanner frame with animated scan line (native only)
          if (_isNative) _buildScannerFrame(),

          const SizedBox(height: 24),

          Text(
            _isNative
                ? 'Point camera at a PayPulse QR code'
                : 'Upload a QR code image from your gallery',
            style: AppTypography.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const Spacer(),

          // Upload QR Image button
          _buildUploadButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: _glassButton(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Text(
            'Scan QR',
            style: AppTypography.title.copyWith(color: Colors.white),
          ),
          if (_isNative)
            GestureDetector(
              onTap: () {
                setState(() => _torchOn = !_torchOn);
                _controller?.toggleTorch();
              },
              child: _glassButton(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                active: _torchOn,
                activeColor: AppColors.warning,
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _glassButton(IconData icon,
      {double size = 20,
      bool active = false,
      Color activeColor = AppColors.warning}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon,
              color: active ? activeColor : Colors.white, size: size),
        ),
      ),
    );
  }

  Widget _buildScannerFrame() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (context, child) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            children: [
              CustomPaint(
                  size: const Size(260, 260), painter: _CornerPainter()),
              // Animated gradient scan line
              Positioned(
                top: 8 + (_scanLineController.value * 226),
                left: 8,
                right: 8,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Colors.transparent,
                      AppColors.primary,
                      AppColors.secondary,
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.88, 0.88));
  }

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isAnalyzingImage ? null : _pickImageAndScan,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: _isAnalyzingImage
                        ? const LinearGradient(
                            colors: [Color(0xFF334155), Color(0xFF334155)])
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05)
                            ],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: _isAnalyzingImage
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white54, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Analyzing QR...',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.photo_library_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Upload QR Image',
                                    style: AppTypography.button
                                        .copyWith(color: Colors.white)),
                                Text('Pick from camera roll or gallery',
                                    style: AppTypography.caption.copyWith(
                                        color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white24, size: 16),
                          ],
                        ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ── Corner Frame Painter ────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    const cL = 30.0; // corner length
    const r = 10.0; // corner arc radius

    void drawCorner(Offset o, double startAngle) {
      final dx = (startAngle == 180 || startAngle == 90) ? 1.0 : -1.0;
      final dy = (startAngle == 180 || startAngle == 270) ? 1.0 : -1.0;

      canvas.drawLine(
          Offset(o.dx + dx * r, o.dy), Offset(o.dx + dx * cL, o.dy), paint);
      canvas.drawLine(
          Offset(o.dx, o.dy + dy * r), Offset(o.dx, o.dy + dy * cL), paint);
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(o.dx + dx * r, o.dy + dy * r),
            width: r * 2,
            height: r * 2),
        startAngle * (3.14159 / 180),
        90 * (3.14159 / 180),
        false,
        paint,
      );
    }

    drawCorner(Offset.zero, 180); // top-left
    drawCorner(Offset(size.width, 0), 270); // top-right
    drawCorner(Offset(0, size.height), 90); // bottom-left
    drawCorner(Offset(size.width, size.height), 0); // bottom-right
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}

// ── QR Scan Success Bottom Sheet ────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final String email;
  final String name;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const _SuccessSheet({
    required this.email,
    required this.name,
    required this.isDark,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white24 : AppColors.border,
                    width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),

              // Success icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: Colors.white, size: 36),
              ).animate().scale(
                  begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),

              const SizedBox(height: 20),

              Text('QR Scanned!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary))
                  .animate()
                  .fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              Text('Ready to send money to',
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary))
                  .animate()
                  .fadeIn(delay: 150.ms),
              const SizedBox(height: 16),

              // Recipient card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'Unknown User' : name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onSend,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Center(
                          child: Text('Send Money',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
