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

  late Instrument selectedInstrument;
  late List<Map<String, String>> chords;

  extractSettings() {
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);

    // Load chords
    final chordStrings = widget.prefs!.getStringList('chords') ?? [];
    chords = chordStrings.map((chordStr) {
      final parts = chordStr.split(':');
      return {
        'key': parts.length > 0 ? parts[0] : 'C',
        'type': parts.length > 1 ? parts[1] : 'major',
      };
    }).toList();

    print("Instrument: $selectedInstrument");
    print("Chords: $chords");

    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  Future<void> saveSettings() async {
    setState(() {
      widget.prefs?.setString('instrument', selectedInstrument.name);

      // Save chords
      final chordStrings = chords.map((chord) => '${chord['key']}:${chord['type']}').toList();
      widget.prefs?.setStringList('chords', chordStrings);

      MidiPro().selectInstrument(
          sfId: widget.sfID,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);

      print('settings saved');
    });
  }

  void addChord() {
    setState(() {
      chords.add({'key': 'C', 'type': 'major'});
    });
  }

  void removeChord(int index) {
    setState(() {
      if (chords.length > 1) {
        chords.removeAt(index);
      }
    });
  }

  void updateChord(int index, String key, String type) {
    setState(() {
      chords[index] = {'key': key, 'type': type};
    });
  }

  @override
  void initState() {
    super.initState();
    extractSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Disable default back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Cancel',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                saveSettings();
                Navigator.pop(context);
              },
              tooltip: 'Save and Close',
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
                    // Instrument settings
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(
                        labelText: 'Instrument',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        isDense: true,
                      ),
                      initialValue: selectedInstrument,
                      isExpanded: true,
                      items: Instrument.values
                          .map((instrument) => DropdownMenuItem(
                                value: instrument,
                                child: Text(instrument.name,
                                    style: TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedInstrument = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Chord Progression Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chord Progression',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.add_circle),
                          onPressed: addChord,
                          tooltip: 'Add Chord',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // List of chords
                    ...List.generate(chords.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Chord number
                                Container(
                                  width: 30,
                                  child: Text('${index + 1}.',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 8),
                                
                                // Key selector
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Key',
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 10.0),
                                      isDense: true,
                                    ),
                                    value: chords[index]['key'],
                                    items: KeyCenter.values
                                        .map((k) => DropdownMenuItem(
                                              value: k.name,
                                              child: Text(k.name,
                                                  style: TextStyle(fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (newValue) {
                                      updateChord(index, newValue!,
                                          chords[index]['type']!);
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                
                                // Type selector
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Type',
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 10.0),
                                      isDense: true,
                                    ),
                                    value: chords[index]['type'],
                                    items: ChordType.values
                                        .map((t) => DropdownMenuItem(
                                              value: t.name,
                                              child: Text(t.name,
                                                  style: TextStyle(fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (newValue) {
                                      updateChord(index, chords[index]['key']!,
                                          newValue!);
                                    },
                                  ),
                                ),
                                
                                // Delete button
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20),
                                  onPressed: chords.length > 1
                                      ? () => removeChord(index)
                                      : null,
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
