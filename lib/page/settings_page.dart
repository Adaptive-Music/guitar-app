import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final int sfID1;
  final int sfID2;
  final SharedPreferences? prefs;

  const SettingsPage({
    super.key, 
    required this.prefs, 
    required this.sfID1, 
    required this.sfID2
  });

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

  // Use KeyCenter enum values for key harmony selection
  List<String> get selectionKeyHarmony => KeyCenter.values.map((k) => k.name).toList();
  
  late List<String> selectionPlayingMode;
  
  // Use Scale enum values for scale selection
  List<String> get selectionScale => Scale.values.map((s) => s.name).toList();
  
  List<String> selectionOctave = ['2', '3', '4', '5', '6', '7'];

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
    
    print("Key Harmony: $selectedKeyHarmony");
    print("Scale: $selectedScale");
    print("Octave: $selectedOctave");
    print("Octave2: $selectedOctave2");
    print("Instrument: $selectedInstrument");
    print("Instrument2: $selectedInstrument2");
    print("Playing Mode: $selectedPlayingMode");
    print("Playing Mode2: $selectedPlayingMode2");
    
    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  loadSelections() {
    // Get the Scale enum value from the selected scale name
    final scale = Scale.values.firstWhere((s) => s.name == selectedScale);
    
    if (scale == Scale.pentatonicMajor || scale == Scale.pentatonicMinor) {
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
      
      MidiPro().selectInstrument(
          sfId: widget.sfID1,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);
      MidiPro().selectInstrument(
          sfId: widget.sfID2,
          bank: selectedInstrument2.bank,
          program: selectedInstrument2.program);
          
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                saveSettings();
                Navigator.pop(context);
              },
              tooltip: 'Save Settings',
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Global settings row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Key',
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                              isDense: true,
                            ),
                            value: selectedKeyHarmony,
                            items: selectionKeyHarmony
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value, style: TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedKeyHarmony = newValue!;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Scale',
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                              isDense: true,
                            ),
                            value: selectedScale,
                            items: selectionScale
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value, style: TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedScale = newValue!;
                              });
                              loadSelections();
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    Divider(height: 16),
                    
                    // Settings columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Frog settings column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Frog Header
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/icon/icon.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Frog',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Frog settings
                              DropdownButtonFormField<Instrument>(
                                decoration: InputDecoration(
                                  labelText: 'Instrument',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                initialValue: selectedInstrument,
                                isExpanded: true,
                                items: Instrument.values
                                    .map((instrument) => DropdownMenuItem(
                                          value: instrument,
                                          child: Text(instrument.name, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedInstrument = newValue!;
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Octave',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                value: selectedOctave,
                                items: selectionOctave
                                    .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedOctave = newValue!;
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Play Mode',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                value: selectedPlayingMode,
                                isExpanded: true,
                                items: selectionPlayingMode
                                    .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedPlayingMode = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 12), // Space between columns
                        
                        // App settings column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Header
                              Row(
                                children: [
                                  Text('📱', style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 8),
                                  Text(
                                    'App',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // App settings
                              DropdownButtonFormField<Instrument>(
                                decoration: InputDecoration(
                                  labelText: 'Instrument',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                initialValue: selectedInstrument2,
                                isExpanded: true,
                                items: Instrument.values
                                    .map((instrument) => DropdownMenuItem(
                                          value: instrument,
                                          child: Text(instrument.name, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedInstrument2 = newValue!;
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Octave',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                value: selectedOctave2,
                                items: selectionOctave
                                    .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedOctave2 = newValue!;
                                  });
                                },
                              ),
                              SizedBox(height: 8),
                              
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Play Mode',
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                  isDense: true,
                                ),
                                value: selectedPlayingMode2,
                                isExpanded: true,
                                items: selectionPlayingMode
                                    .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value, style: TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedPlayingMode2 = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Commented out sections preserved but not active
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
