import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/widgets/KeyBoard.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MidiPro _midi = MidiPro();
  int sfID = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSoundFont();
    
  }

  // Function to load the SoundFont
  Future<void> loadSoundFont() async {
    sfID = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: 0,
      program: 0,
    );
    setState(() {
      _isLoading = false;
      print('loaded');
    });
        // _midi.prepare(sf2: sf2);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading screen while waiting for async task to complete
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Scaffold(
        appBar: AppBar(
          title: Text('Full Screen 2 Rows of 7 Buttons'),
        ),
        body: KeyBoard(keyHarmony: 0, octave: 60,  scale: 'major', sfID: sfID, midiController: _midi),
      ),
    );
  }


  @override
  void dispose() {
    // _midi.unload(); // Unload the SoundFont when the widget is disposed
    super.dispose();
  }
}
