import 'dart:io';
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
  late int sfID1;
  late int sfID2;

  SharedPreferences? _prefs;
  Instrument selectedInstrument1 = Instrument.values[0]; // Default value
  Instrument selectedInstrument2 = Instrument.values[0];

  bool _sfLoading = true;
  bool _midiConnecting = false;
  bool _prefLoading = true;

  List<MidiDevice>? midiDevices = [];
  MidiDevice? selectedMidiDevice;

  Future<void> loadSoundFont() async {
    if (_prefs == null) return; // Don't load if prefs aren't ready
    
    String? instrumentName = _prefs?.getString('instrument');
    selectedInstrument1 = instrumentName != null 
        ? Instrument.values.firstWhere((e) => e.name == instrumentName)
        : Instrument.values[0];

    String? instrument2Name = _prefs?.getString('instrument2');
    selectedInstrument2 = instrument2Name != null
        ? Instrument.values.firstWhere((e) => e.name == instrument2Name)
        : Instrument.values[0];

    sfID1 = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: selectedInstrument1.bank,
      program: selectedInstrument1.program,
    );

    sfID2 = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: selectedInstrument2.bank,
      program: selectedInstrument2.program,
    );

    setState(() {
      _sfLoading = false;
    });  
  }

  Future<void> connectMidiDevice() async {
    if (_midiConnecting) return;
    setState(() {
      _midiConnecting = true;
    });
    if (selectedMidiDevice != null) {
      print('Device: ${selectedMidiDevice!.name}');
      print('Connected: ${selectedMidiDevice!.connected}');
    }
    final newMidiDevices = await _midi_cmd.devices;
    print('Found MIDI devices: $newMidiDevices');
    if (newMidiDevices != null && !newMidiDevices.contains(selectedMidiDevice)) {
      print('Previously selected MIDI device no longer available');
      selectedMidiDevice = null;
    }
    if (selectedMidiDevice != null && selectedMidiDevice!.connected) {
      print('MIDI device ${selectedMidiDevice!.name} is already connected.');
      print(selectedMidiDevice!.connected);
      setState(() {
        _midiConnecting = false;
      });
      return;
    }
    for (var device in newMidiDevices!) {
      if (
        device.name.contains("Teensy") || 
        // device.name.contains("MIDI") ||
        (device.name.contains("Zoe") && !Platform.isAndroid)) {
        print(device.name);
        if(device.connected) {
          print('Device ${device.name} is already connected.');
          selectedMidiDevice = device;
          setState(() {
            _midiConnecting = false;
          });
          return;
        }
        await _midi_cmd.connectToDevice(device);
        print('Connected to ${device.name}.');
        selectedMidiDevice = device;
        testLEDs(2);
        break;
      }
    }
    if (selectedMidiDevice == null || !selectedMidiDevice!.connected) {
      print('No suitable MIDI device found or connection failed.');
      selectedMidiDevice = null;
    }
    setState(() {
      _midiConnecting = false;
    });
  }

  void selectMidiDevice() async {
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
    await connectMidiDevice();
    _midi_cmd.onMidiSetupChanged?.listen((data) async {
      // Handle MIDI setup changes
      await connectMidiDevice();
    });
    // selectMidiDevice();
    setState(() {
      _prefLoading = false;
      print('Pref loaded');
    }); 
  }



  _checkPrefs() async {
    if (_prefs?.getString('keyHarmony') == null) {
      await _prefs?.setString('keyHarmony', 'C');
    }
    
    if (_prefs?.getString('currentScale') == null) {
      _prefs?.setString('currentScale', 'Major');
    }

    if (_prefs?.getString('octave') == null) {
      _prefs?.setString('octave', '4');
    }

    if (_prefs?.getString('octave2') == null) {
      _prefs?.setString('octave2', '4');
    }

    if (_prefs?.getString('instrument') == null) {
      _prefs?.setString('instrument', Instrument.values[0].name);
    }

    if (_prefs?.getString('instrument2') == null) {
      _prefs?.setString('instrument2', Instrument.values[0].name);
    }

    if (_prefs?.getString('playingMode') == null) {
      _prefs?.setString('playingMode', 'Single Note');
    }

    if (_prefs?.getString('playingMode2') == null) {
      _prefs?.setString('playingMode2', 'Single Note');
    }

    // if (_prefs?.getString('visuals') == null) {
    //   _prefs?.setString('visuals', 'Grid');
    // }

    //  if (_prefs?.getString('symbols') == null) {
    //   _prefs?.setString('symbols', 'Shapes');
    // }

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
      title: 'TadBuddy',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Builder(
        builder: (context) {
          if (_sfLoading || _prefLoading || _midiConnecting) {
          // Show a loading screen while waiting for async task to complete
            return Scaffold(
              body: Text('Loading...'),
            );
          }
        return HomeScreen(
          prefs: _prefs, 
          sfID1: sfID1, 
          sfID2: sfID2, 
          midiController: _midi, 
          midiCommand: _midi_cmd,
          selectedMidiDevice: selectedMidiDevice,
        );
        }, 
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final SharedPreferences? prefs;
  final int sfID1;
  final int sfID2;
  final MidiPro midiController;
  final MidiCommand midiCommand;
  final MidiDevice? selectedMidiDevice;
  const HomeScreen({
    super.key, 
    required this.sfID1, 
    required this.sfID2, 
    required this.midiController, 
    required this.prefs, 
    required this.midiCommand,
    required this.selectedMidiDevice,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  late int keyHarmony;
  late KeyCenter keyCentre;
  late int octave1;
  late int octave2;
  late Scale scale;
  late List<int> scaleIntervals;
  late String playingMode1;
  late String playingMode2;
  int frogVolume = 127;
  int appVolume = 127;

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
      keyCentre = KeyCenter.values.firstWhere((key) => key.key == keyHarmony);
      octave1 = Octave.getNum(widget.prefs!.getString('octave')!);
      octave2 = Octave.getNum(widget.prefs!.getString('octave2')!);
      scale = Scale.getScale(widget.prefs!.getString('currentScale')!);
      scaleIntervals = Scale.getIntervals(scale.name);
      playingMode1 = widget.prefs!.getString('playingMode')!;
      playingMode2 = widget.prefs!.getString('playingMode2')!;
    });
    print("Extracted - Key Harmony: $keyHarmony");
    print("Extracted - Octave: $octave1");
    print("Extracted - Octave2: $octave2");
    print("Extracted - Scale: $scaleIntervals");
    print("Extracted - Playing Mode: $playingMode1");
    print("Extracted - Playing Mode2: $playingMode2");

    print('Settings extracted');
  }

  @override

  
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('${keyCentre.getName(scale)} ${widget.prefs?.getString('currentScale')}'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Go to Settings',
              onPressed: () {
                Navigator.push(
                  context,
                 MaterialPageRoute(builder: (context) => SettingsPage(prefs: widget.prefs, sfID1: widget.sfID1, sfID2: widget.sfID2, )),
              ).then((value) {
                extractSettings();
              });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Volume controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Opacity(
                              opacity: widget.selectedMidiDevice == null ? 0.2 : 1.0,
                              child: Image.asset(
                                'assets/images/frog.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: widget.selectedMidiDevice == null ? 0.2 : 1.0,
                        child: SizedBox(
                          width: 150,
                          child: Slider(
                            value: frogVolume / 127,
                            min: 0,
                            max: 1,
                            onChanged: (value) {
                              setState(() {
                                frogVolume = (value * 127).round();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.selectedMidiDevice == null ?
                          'Instrument not connected' :
                          '${widget.prefs?.getString('instrument')} - '
                          'Octave ${widget.prefs?.getString('octave')} - '
                          '${widget.prefs?.getString('playingMode')}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // App volume control
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('📱', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          value: appVolume / 127,
                          min: 0,
                          max: 1,
                          onChanged: (value) {
                            setState(() {
                              appVolume = (value * 127).round();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${widget.prefs?.getString('instrument2')} - '
                          'Octave ${widget.prefs?.getString('octave2')} - '
                          '${widget.prefs?.getString('playingMode2')}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Keyboard
            Expanded(
              child: KeyBoard(
                keyHarmony: keyHarmony, 
                octave1: octave1, 
                octave2: octave2, 
                scale: scale,
                sfID1: widget.sfID1, 
                sfID2: widget.sfID2, 
                midiController: widget.midiController, 
                midiCommand: widget.midiCommand, 
                playingMode1: playingMode1, 
                playingMode2: playingMode2,
                frogVolume: frogVolume,
                appVolume: appVolume
              ),
            ),
          ],
        ),
      );
  }
}

