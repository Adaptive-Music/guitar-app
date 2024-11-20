import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/settings_page.dart';
import 'package:flutter_application_1/widgets/KeyBoard.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';



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

  SharedPreferences? _prefs;

  bool _sfLoading = true;
  bool _prefLoading = true;

  // Function to load the SoundFont
  Future<void> loadSoundFont() async {
    sfID = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: 0,
      program: 0,
    );
    setState(() {
      _sfLoading = false;
      print('SF loaded');
    });  
  }

  Future<void> _initPrefs() async {
      _prefs = await SharedPreferences.getInstance();
      _checkPrefs();
      setState(() {
        _prefLoading = false;
        print('Pref loaded');
      }); 
  }


  _checkPrefs() async {
    if (_prefs?.getString('keyHarmony') == null) {
      await _prefs?.setString('keyHarmony', 'C');
    }
    
    if (_prefs?.getString('octave') == null) {
      _prefs?.setString('octave', '4');
    }

    if (_prefs?.getString('currentScale') == null) {
      _prefs?.setString('currentScale', 'Major');
    }
    
    if (_prefs?.getString('instrument') == null) {
      _prefs?.setString('instrument', Instrument.values[0].name);
    }

    if (_prefs?.getString('playingMode') == null) {
      _prefs?.setString('playingMode', 'Single Note');
    }

    if (_prefs?.getString('visuals') == null) {
      _prefs?.setString('visuals', 'Grid');
    }

     if (_prefs?.getString('symbols') == null) {
      _prefs?.setString('symbols', 'Shapes');
    }

    print("Key Harmony: ${_prefs?.getString('keyHarmony')}");
    print("Octave: ${_prefs?.getString('octave')}");
    print("Scale: ${_prefs?.getString('currentScale')}");
    print("Instrument: ${_prefs?.getString('instrument')}");
    print("Playing Mode: ${_prefs?.getString('playingMode')}");
    print("Visual: ${_prefs?.getString('visuals')}");
    print("Symbols: ${_prefs?.getString('symbols')}");

    print('checkPrefs called');
  }

  @override
  void initState() {
    super.initState();
    loadSoundFont();
    _initPrefs();
  }

    

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Builder(
        builder: (context) {
          if (_sfLoading || _prefLoading) {
          // Show a loading screen while waiting for async task to complete
            return Scaffold(
              body: Text('Loading...'),
            );
          }
        return HomeScreen(prefs: _prefs, sfID: sfID, midiController: _midi);
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
  final SharedPreferences? prefs;
  final int sfID;
  final MidiPro midiController;
  const HomeScreen({super.key, required this.sfID, required this.midiController, required this.prefs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  late int keyHarmony;
  late int octave;
  late List<int> scale;
  late String playingMode;


  @override
  void initState() {
    super.initState();
    extractSettings();
  }

  void extractSettings() {
    setState(() {
      keyHarmony = KeyCenter.getKey(widget.prefs!.getString('keyHarmony')!);
      octave = Octave.getNum(widget.prefs!.getString('octave')!);
      scale = Scale.getIntervals(widget.prefs!.getString('currentScale')!);
      playingMode = widget.prefs!.getString('playingMode')!;
    });
    print("Extracted - Key Harmony: $keyHarmony");
    print("Extracted - Octave: $octave");
    print("Extracted - Scale: $scale");
    print("Extracted - Playing Mode: $playingMode");

    print('Settings extracted');
  }

  @override

  
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Full Screen 2 Rows of 7 Buttons'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Go to Settings',
              onPressed: () {
                Navigator.push(
                  context,
                 MaterialPageRoute(builder: (context) => SettingsPage(prefs: widget.prefs, sfID: widget.sfID, )),
              ).then((value) {
                extractSettings();
              });
              },
            ),
          ],
        ),
        body: KeyBoard(keyHarmony: keyHarmony, octave: octave,  scale: scale, 
        sfID: widget.sfID, midiController: widget.midiController, playingMode: playingMode),
      );
  }
}

