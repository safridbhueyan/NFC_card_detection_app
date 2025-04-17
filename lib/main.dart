import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Reader',
      home: NfcReaderPage(),
    );
  }
}

class NfcReaderPage extends StatefulWidget {
  @override
  _NfcReaderPageState createState() => _NfcReaderPageState();
}

class _NfcReaderPageState extends State<NfcReaderPage> {
  String _nfcData = 'Scan a tag...';
  bool _isScanning = false;

  void extractCardIdFromRawNfcData(String rawData) {
    final regex = RegExp(r'identifier: \[([0-9,\s]+)\]');
    final match = regex.firstMatch(rawData);

    if (match != null) {
      final rawList = match.group(1); // e.g. "92, 30, 135, 159"
      final cardId = rawList!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

      print('✅ Extracted Card ID: $cardId');

      // Now you can send cardId to your backend
      // Example: sendCardIdToBackend(cardId);
    } else {
      print('❌ Card identifier not found.');
    }
  }


  void _startScanning() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() => _nfcData = 'NFC is not available on this device');
      return;
    }

    setState(() => _isScanning = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _nfcData = tag.data.toString();
          debugPrint("\n$_nfcData\n");
         // final String cardId = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
          extractCardIdFromRawNfcData(_nfcData);
        //  print('Card ID: $cardId');

          _isScanning = false;
        });
        NfcManager.instance.stopSession();
      },
      onError: (error) async {
        setState(() {
          _nfcData = 'Error reading NFC tag: $error';
          _isScanning = false;
        });
        NfcManager.instance.stopSession(errorMessage: error.toString());
      },
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFC Reader')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_nfcData, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isScanning ? null : _startScanning,
              child: Text('Start NFC Scan'),
            ),
          ],
        ),
      ),
    );
  }
}