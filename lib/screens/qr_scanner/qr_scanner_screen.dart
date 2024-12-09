import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import '../../services/scan_service.dart';
import '../../services/card_service.dart';
import 'dart:io';
import '../qr_scanner/scanned_card_preview_screen.dart';
import '../../services/analytics_service.dart';
import '../../config/theme.dart';
import '../../utils/app_error.dart';
import '../../utils/error_display.dart';
import '../../services/location_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool _flashOn = false;
  final _scanService = ScanService();
  final _cardService = CardService();
  final _analyticsService = AnalyticsService();

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (Platform.isIOS)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: _simulateScan,
            ),
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.secondary,
              borderRadius: 12,
              borderLength: 32,
              borderWidth: 12,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
              overlayColor: Colors.black87,
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Align QR code within frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scanning will start automatically',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _toggleFlash() async {
    try {
      await controller?.toggleFlash();
      final flash = await controller?.getFlashStatus() ?? false;
      setState(() => _flashOn = flash);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _flipCamera() async {
    try {
      await controller?.flipCamera();
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  Future<void> _processQRCode(String data) async {
    try {
      setState(() => _isProcessing = true);

      final locationData = await LocationService().getCurrentLocation();
      debugPrint('Location data for QR scan: $locationData');

      final qrData = jsonDecode(data);
      if (qrData['type'] != 'digital_card' || qrData['id'] == null) {
        throw AppError(message: 'Invalid QR code format', type: ErrorType.scan);
      }

      await _scanService.recordScan(
        cardId: qrData['id'],
        scannerUserId: 'anonymous',
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      );

      final cards = await _cardService.searchCards(query: qrData['id']);
      if (cards.isEmpty) throw 'Card not found';

      if (mounted) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ScannedCardPreviewScreen(card: cards.first),
          ),
        );

        if (saved == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card saved to your collection')),
          );
        }

        await controller?.resumeCamera();
      }

      await _analyticsService.recordScan(
        cardId: cards.first.id,
        eventType: CardAnalyticEvent.scan,
        details: ScanDetails(
          deviceType: 'mobile',
          platform: Platform.isIOS ? 'iOS' : 'Android',
          source: 'qr_scan',
          city: locationData['city'],
          country: locationData['country'],
          location: locationData['coordinates'],
        ),
      );
    } catch (e, stackTrace) {
      final error = AppError.handleError(e, stackTrace);
      if (mounted) {
        ErrorDisplay.showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        await controller?.resumeCamera();
      }
    }
  }

  Future<void> _simulateScan() async {
    try {
      setState(() => _isProcessing = true);

      final testCardId = await _cardService.getRandomCardForTesting();
      if (testCardId == null) {
        throw 'No cards available for testing';
      }

      await _analyticsService.recordScan(
        cardId: testCardId,
        eventType: CardAnalyticEvent.scan,
        details: ScanDetails(
          deviceType: 'mobile',
          platform: Platform.isIOS ? 'iOS' : 'Android',
          source: 'test_scan',
          isTestScan: true,
          city: 'Test City',
          country: 'Test Country',
          location: {
            'latitude': 0.0,
            'longitude': 0.0,
            'address': 'Test Location'
          },
        ),
      );

      await _processQRCode(jsonEncode({
        'type': 'digital_card',
        'id': testCardId,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('Simulation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
