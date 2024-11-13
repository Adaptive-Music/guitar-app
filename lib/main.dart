import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/page/settings_page.dart';
import 'package:flutter_application_1/widgets/KeyBoard.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/special/enums.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MidiPro _midi = MidiPro();
  int sfID = 0;
  bool _isLoading = true;
  Scale currentScale = Scale.minor;
  PMode playingMode = PMode.tChord;

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
    });   // _midi.prepare(sf2: sf2);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Builder(
        builder: (context) {
          if (_isLoading) {
          // Show a loading screen while waiting for async task to complete
            return Scaffold(
              body: Text('Loading...'),
            );
          }
        return HomeScreen(keyHarmony: 0, octave: 60, scale: currentScale, sfID: sfID, midiController: _midi, playingMode: playingMode);
        },
      ),
    );
  }




  @override
  void dispose() {
    // _midi.unload(); // Unload the SoundFont when the widget is disposed
    super.dispose();
  }
}


class HomeScreen extends StatefulWidget {
  final int keyHarmony;
  final Scale scale;
  final int octave;
  final PMode playingMode;
  final int sfID;
  final MidiPro midiController;
  const HomeScreen({super.key, required this.keyHarmony, required this.scale, 
  required this.octave, required this.sfID, required this.midiController, required this.playingMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Full Screen 2 Rows of 7 Buttons'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Go to Settings',
              onPressed: () {
                Navigator.push(
                  context,
                 MaterialPageRoute(builder: (context) => SettingsPage(option1: 'Option 1A', option2: 'Option 2A',)),
              );
              },
            ),
          ],
        ),
        body: KeyBoard(keyHarmony: widget.keyHarmony, octave: widget.octave,  
        scale: widget.scale, sfID: widget.sfID, midiController: widget.midiController, playingMode: widget.playingMode),
      );
  }
}

