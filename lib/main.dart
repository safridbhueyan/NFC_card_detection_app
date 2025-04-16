import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('NFC Reader')),
        body: const NfcReaderScreen(),
      ),
    );
  }
}

class NfcReaderScreen extends StatefulWidget {
  const NfcReaderScreen({super.key});

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen> {
  String result = 'Tap a card to scan';
  bool isLoading = false;
  String? rawResponse;

  Future<void> startNfcScan() async {
    setState(() {
      isLoading = true;
      result = '🔍 Scanning for NFC tag...';
      rawResponse = null;
    });

    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          result = '❌ NFC is not available: $availability';
          isLoading = false;
        });
        return;
      }

      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 30));

      String info = '''
✅ NFC Tag Detected
--------------------------
• ID: ${tag.id}
• Type: ${tag.type}
• Standard: ${tag.standard}
• ATQA: ${tag.atqa}
• SAK: ${tag.sak}
• Historical Bytes: ${tag.historicalBytes}
• Protocol Info: ${tag.protocolInfo}
--------------------------
''';

      if (tag.type == NFCTagType.iso7816) {
        final apdu = "00A4040007A0000000031010"; // Visa AID
        final response = await FlutterNfcKit.transceive(apdu);
        info += '📥 APDU Response: $response\n';
        rawResponse = response;
      } else {
        info += '⚠️ This tag is not ISO7816 (e.g., not an EMV card).';
      }

      await FlutterNfcKit.finish();

      setState(() {
        result = info;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = '❌ NFC Error: $e';
        isLoading = false;
      });
    }
  }

  void copyToClipboard() {
    if (rawResponse != null) {
      Clipboard.setData(ClipboardData(text: rawResponse!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied response to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Text(
                result,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: startNfcScan,
              icon: const Icon(Icons.nfc),
              label: const Text('Start NFC Scan'),
            ),
            if (rawResponse != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Raw Response'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
