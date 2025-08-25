import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/settings_page.dart';
import 'package:flutter_application_1/widgets/KeyBoard.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Portrait Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight, 
  ]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MidiPro _midi = MidiPro();
  final MidiCommand _midi_cmd = MidiCommand();
  int sfID = 0;

  SharedPreferences? _prefs;
  Instrument selectedInstrument = Instrument.values[0]; // Default value

  bool _sfLoading = true;
  bool _midiCmdLoading = true;
  bool _prefLoading = true;

  List<MidiDevice>? midiDevices = [];
  MidiDevice? selectedMidiDevice;

  Future<void> loadSoundFont() async {
    if (_prefs == null) return; // Don't load if prefs aren't ready
    
    String? instrumentName = _prefs?.getString('instrument');
    selectedInstrument = instrumentName != null 
        ? Instrument.values.firstWhere((e) => e.name == instrumentName)
        : Instrument.values[0];

    sfID = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: selectedInstrument.bank,
      program: selectedInstrument.program,
    );
    setState(() {
      _sfLoading = false;
    });  
  }

  Future<void> setMidiDevices() async {
    final newMidiDevices = await _midi_cmd.devices;
    
    setState(() {
      midiDevices = newMidiDevices;
      _midiCmdLoading = false;
    });
  }

  void selectMidiDevice() async {
    for (var device in midiDevices!) {
      if (
        device.name.contains("Teensy") || 
        // device.name.contains("Zoe") ||
        device.name.contains("MIDI")
        ) {
        await _midi_cmd.connectToDevice(device);
        print('Connected to ${device.name}.');
        print(midiDevices);
        break;
      }
    }
  testLEDs(2);
  }

  /// Cycle through the LEDs on the connected MIDI device.
  Future<void> testLEDs(int cycles) async {
    List<int> notes = [60, 62, 64, 65, 67, 69];
    
    for (int i = 0; i < cycles; i++) {
      for (int i in notes) {
        sendNoteOn(i);
        await Future.delayed(Duration(milliseconds: 100));
        sendNoteOff(i);
      }
    }
  
  }
  
  void sendNoteOn(note) {

    final noteOn = Uint8List.fromList([0x90, note, 100]);

    _midi_cmd.sendData(noteOn);
  }

  void sendNoteOff(note) {
    final noteOff = Uint8List.fromList([0x80, note, 0]);
    _midi_cmd.sendData(noteOff);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkPrefs();
    await loadSoundFont(); // Move soundfont loading here
    await setMidiDevices();
    selectMidiDevice();
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

    // print("Key Harmony: ${_prefs?.getString('keyHarmony')}");
    // print("Octave: ${_prefs?.getString('octave')}");
    // print("Scale: ${_prefs?.getString('currentScale')}");
    // print("Instrument: ${_prefs?.getString('instrument')}");
    // print("Playing Mode: ${_prefs?.getString('playingMode')}");
    // print("Visual: ${_prefs?.getString('visuals')}");
    // print("Symbols: ${_prefs?.getString('symbols')}");

    // print('checkPrefs called');
  }

  @override
  void initState() {
    super.initState();
    _initPrefs(); // Only call _initPrefs, which will handle loadSoundFont
    
    // Enable wakelock to prevent screen timeout
    WakelockPlus.enable();
  }
  
  @override
  void dispose() {
    // Disable wakelock when the app is closed
    WakelockPlus.disable();
    super.dispose();
  }

    

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Builder(
        builder: (context) {
          if (_sfLoading || _prefLoading || _midiCmdLoading) {
          // Show a loading screen while waiting for async task to complete
            return Scaffold(
              body: Text('Loading...'),
            );
          }
        return HomeScreen(prefs: _prefs, sfID: sfID, midiController: _midi, midiCommand: _midi_cmd);
        }, 
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final SharedPreferences? prefs;
  final int sfID;
  final MidiPro midiController;
  final MidiCommand midiCommand;
  const HomeScreen({super.key, required this.sfID, required this.midiController, required this.prefs, required this.midiCommand});

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
    
    // Make sure wakelock is still enabled when this screen is shown
    WakelockPlus.enable();
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
          title: Text('${widget.prefs?.getString('instrument')} - '
              '${widget.prefs?.getString('keyHarmony')} ${widget.prefs?.getString('currentScale')} - '
              'Octave ${widget.prefs?.getString('octave')} - ${widget.prefs?.getString('playingMode')}'),
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
        sfID: widget.sfID, midiController: widget.midiController, midiCommand: widget.midiCommand, playingMode: playingMode),
      );
  }
}

