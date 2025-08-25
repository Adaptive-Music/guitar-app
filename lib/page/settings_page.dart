import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final int sfID;

  final SharedPreferences? prefs;

  const SettingsPage({super.key, required this.prefs, required this.sfID});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool prefLoaded = false;

  late String selectedKeyHarmony;
  late String selectedPlayingMode;
  late String selectedPlayingMode2;
  late String selectedScale;
  late String selectedOctave;
  late String selectedOctave2;
  late Instrument selectedInstrument;
  late Instrument selectedInstrument2;
  // late String selectedVisuals;
  // late String selectedSymbols;

  List<String> selectionKeyHarmony = [
                        'C',
                        'C# / Db',
                        'D',
                        'D# / Eb',
                        'E',
                        'F',
                        'F# / Gb',
                        'G',
                        'G# / Ab',
                        'A',
                        'A# / Bb',
                        'B'
                      ];
  late List<String> selectionPlayingMode;
  List<String> selectionScale = [
                        'Major',
                        'Minor',
                        'Harmonic Minor',
                        'Pentatonic Major',
                        'Pentatonic Minor'
                      ]; 
  List<String> selectionOctave = ['2', '3', '4', '5', '6', '7'];
  // List<String> selectionVisuals = ['Grid', 'Custom'];
  // List<String> selectionSymbols = ['Shapes', 'Letters', 'Numbers', 'None'];

  extractSettings() {
    selectedKeyHarmony = widget.prefs!.getString('keyHarmony')!;
    selectedScale = widget.prefs!.getString('currentScale')!;
    selectedOctave = widget.prefs!.getString('octave')!;
    selectedOctave2 = widget.prefs!.getString('octave2')!;
    selectedPlayingMode = widget.prefs!.getString('playingMode')!;
    selectedPlayingMode2 = widget.prefs!.getString('playingMode2')!;
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);
    selectedInstrument2 = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument2')!);
    // selectedVisuals = widget.prefs!.getString('visuals')!;
    // selectedSymbols = widget.prefs!.getString('symbols')!;
    print("Key Harmony: $selectedKeyHarmony");
    print("Scale: $selectedScale");
    print("Octave: $selectedOctave");
    print("Octave2: $selectedOctave2");
    print("Instrument: $selectedInstrument");
    print("Instrument2: $selectedInstrument2");
    print("Playing Mode: $selectedPlayingMode");
    print("Playing Mode2: $selectedPlayingMode2");
    // print("Visual: $selectedVisuals");
    // print("Symbols: $selectedSymbols");
    setState() {
      prefLoaded = true;
      print('Pref Loaded');
    }
  }

  loadSelections() {
    if (selectedScale == 'Pentatonic Major' || selectedScale == 'Pentatonic Minor') {
      setState(() {
        selectionPlayingMode = ['Single Note', 'Power Chord'];
        selectedPlayingMode = selectedPlayingMode == 'Triad Chord' ? 'Single Note' : selectedPlayingMode;
        selectedPlayingMode2 = selectedPlayingMode2 == 'Triad Chord' ? 'Single Note' : selectedPlayingMode2;
      });
    } else {
      setState(() {
        selectionPlayingMode = ['Single Note', 'Triad Chord', 'Power Chord'];
      });  
    }
    
  }

  Future<void> saveSettings() async {
    setState(() {
      widget.prefs?.setString('keyHarmony', selectedKeyHarmony);
      widget.prefs?.setString('currentScale', selectedScale);
      widget.prefs?.setString('octave', selectedOctave);
      widget.prefs?.setString('octave2', selectedOctave2);
      widget.prefs?.setString('playingMode', selectedPlayingMode);
      widget.prefs?.setString('playingMode2', selectedPlayingMode2);
      widget.prefs?.setString('instrument', selectedInstrument.name);
      widget.prefs?.setString('instrument2', selectedInstrument2.name);
      // widget.prefs?.setString('visuals', selectedVisuals);
      // widget.prefs?.setString('symbols', selectedSymbols);
      MidiPro().selectInstrument(
          sfId: widget.sfID,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);
      print('settings saved');
    });
  }

  @override
  void initState() {
    super.initState();
    extractSettings();
    loadSelections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Key Centre'),
                      value: selectedKeyHarmony,
                      items: selectionKeyHarmony
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedKeyHarmony = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Scale'),
                      value: selectedScale,
                      items: selectionScale
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedScale = newValue!;
                        });
                        loadSelections();
                      },
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('🐸', style: TextStyle(fontSize: 40)), // Frog emoji
                        SizedBox(width: 10),
                        Text('Frog Settings', style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        )),
                      ],
                    ),
                    // SizedBox(height: 16),
                    
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(labelText: 'Instrument'),
                      initialValue: selectedInstrument,
                      items: Instrument.values
                          .map((instrument) => DropdownMenuItem(
                                value: instrument,
                                child: Text(instrument.name),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedInstrument = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Octave'),
                      value: selectedOctave,
                      items: selectionOctave
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedOctave = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Keyboard Mode'),
                      value: selectedPlayingMode,
                      items: selectionPlayingMode
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedPlayingMode = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('📱', style: TextStyle(fontSize: 40)), // Frog emoji
                        SizedBox(width: 10),
                        Text('App Settings', style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        )),
                      ],
                    ),
                    // SizedBox(height: 16),
                    
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(labelText: 'Instrument'),
                      initialValue: selectedInstrument2,
                      items: Instrument.values
                          .map((instrument) => DropdownMenuItem(
                                value: instrument,
                                child: Text(instrument.name),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedInstrument2 = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Octave'),
                      value: selectedOctave2,
                      items: selectionOctave
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedOctave2 = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Keyboard Mode'),
                      value: selectedPlayingMode2,
                      items: selectionPlayingMode
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedPlayingMode2 = newValue!;
                        });
                      },
                    ),
                    // SizedBox(height: 16),
                    // DropdownButtonFormField<String>(
                    //   decoration: InputDecoration(labelText: 'Visuals'),
                    //   value: selectedVisuals,
                    //   items: selectionVisuals
                    //       .map((value) => DropdownMenuItem(
                    //             value: value,
                    //             child: Text(value),
                    //           ))
                    //       .toList(),
                    //   onChanged: (newValue) {
                    //     setState(() {
                    //       selectedVisuals = newValue!;
                    //     });
                    //   },
                    // ),
                    // SizedBox(height: 16),
                    // DropdownButtonFormField<String>(
                    //   decoration:
                    //       InputDecoration(labelText: 'Keyboard Symbols'),
                    //   value: selectedSymbols,
                    //   items: selectionSymbols
                    //       .map((value) => DropdownMenuItem(
                    //             value: value,
                    //             child: Text(value),
                    //           ))
                    //       .toList(),
                    //   onChanged: (newValue) {
                    //     setState(() {
                    //       selectedSymbols = newValue!;
                    //     });
                    //   },
                    // ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                saveSettings();
                Navigator.pop(context);
              },
              child: Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
