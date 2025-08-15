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
  late String selectedScale;
  late String selectedOctave;
  late Instrument selectedInstrument;
  late String selectedVisuals;
  late String selectedSymbols;

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
  List<String> selectionVisuals = ['Grid', 'Custom'];
  List<String> selectionSymbols = ['Shapes', 'Letters', 'Numbers', 'None'];

  extractSettings() {
    selectedKeyHarmony = widget.prefs!.getString('keyHarmony')!;
    selectedOctave = widget.prefs!.getString('octave')!;
    selectedScale = widget.prefs!.getString('currentScale')!;
    selectedPlayingMode = widget.prefs!.getString('playingMode')!;
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);
    selectedVisuals = widget.prefs!.getString('visuals')!;
    selectedSymbols = widget.prefs!.getString('symbols')!;
    print("Key Harmony: $selectedKeyHarmony");
    print("Octave: $selectedOctave");
    print("Scale: $selectedScale");
    print("Instrument: $selectedInstrument");
    print("Playing Mode: $selectedPlayingMode");
    print("Visual: $selectedVisuals");
    print("Symbols: $selectedSymbols");
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
      widget.prefs?.setString('octave', selectedOctave);
      widget.prefs?.setString('currentScale', selectedScale);
      widget.prefs?.setString('playingMode', selectedPlayingMode);
      widget.prefs?.setString('instrument', selectedInstrument.name);
      widget.prefs?.setString('visuals', selectedVisuals);
      widget.prefs?.setString('symbols', selectedSymbols);
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
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(labelText: 'Instrument'),
                      value: selectedInstrument,
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
