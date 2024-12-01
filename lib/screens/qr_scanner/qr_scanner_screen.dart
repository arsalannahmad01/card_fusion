import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import '../../services/scan_service.dart';
import '../../services/card_service.dart';
import '../card_viewer/card_viewer_screen.dart';
import 'dart:io';
import '../qr_scanner/scanned_card_preview_screen.dart';
import '../../services/analytics_service.dart';

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
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          if (Platform.isIOS)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _simulateScan,
            ),
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
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
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
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
      await controller?.pauseCamera();

      final qrData = jsonDecode(data);
      if (qrData['type'] != 'digital_card' || qrData['id'] == null) {
        throw 'Invalid QR code';
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
        ),
      );
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        await controller?.resumeCamera();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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

      debugPrint('Testing scan for card: $testCardId');

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
