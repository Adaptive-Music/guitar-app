import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  late Map<String, List<Map<String, String>>> savedProgressions;
  late String currentProgressionName;

  extractSettings() {
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);

    // Load current progression name
    currentProgressionName = widget.prefs!.getString('currentProgressionName') ?? 'Default';

    // Load saved progressions
    final progressionsJson = widget.prefs!.getString('savedProgressions');
    if (progressionsJson != null) {
      final decoded = json.decode(progressionsJson) as Map<String, dynamic>;
      savedProgressions = decoded.map((key, value) {
        final chordsList = (value as List).map((chord) {
          return {
            'key': chord['key'] as String,
            'type': chord['type'] as String,
          };
        }).toList();
        return MapEntry(key, chordsList);
      });
    } else {
      savedProgressions = {};
    }

    // Only create Default progression if this is truly first launch (no saved progressions at all)
    if (savedProgressions.isEmpty) {
      // Check if there's old 'chords' data from before the progression system
      final chordStrings = widget.prefs!.getStringList('chords') ?? [];
      if (chordStrings.isNotEmpty) {
        // Migrate old data to Default progression (one-time migration)
        savedProgressions['Default'] = chordStrings.map((chordStr) {
          final parts = chordStr.split(':');
          return {
            'key': parts.length > 0 ? parts[0] : 'C',
            'type': parts.length > 1 ? parts[1] : 'major',
          };
        }).toList();
        // Clear old key so we don't migrate again
        widget.prefs!.remove('chords');
      } else {
        // True first launch - create default progression
        savedProgressions['Default'] = [
          {'key': 'C', 'type': 'major'},
          {'key': 'F', 'type': 'major'},
          {'key': 'G', 'type': 'major'},
          {'key': 'A', 'type': 'minor'},
        ];
      }
    }

    // Load current progression
    if (savedProgressions.containsKey(currentProgressionName)) {
      chords = List.from(savedProgressions[currentProgressionName]!);
    } else {
      currentProgressionName = savedProgressions.keys.first;
      chords = List.from(savedProgressions[currentProgressionName]!);
    }

    print("Instrument: $selectedInstrument");
    print("Current Progression: $currentProgressionName");
    print("Chords: $chords");

    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  Future<void> saveSettings() async {
    // Save current progression (make a copy)
    savedProgressions[currentProgressionName] = List.from(chords.map((chord) => Map<String, String>.from(chord)));

    // Convert to JSON
    final progressionsJson = json.encode(savedProgressions);

    await widget.prefs?.setString('instrument', selectedInstrument.name);
    await widget.prefs?.setString('savedProgressions', progressionsJson);
    await widget.prefs?.setString('currentProgressionName', currentProgressionName);

    MidiPro().selectInstrument(
        sfId: widget.sfID,
        bank: selectedInstrument.bank,
        program: selectedInstrument.program);

    print('settings saved');
    print('Saved progression: $currentProgressionName');
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

  void loadProgression(String name) {
    print('Loading progression: $name');
    print('Available progressions: ${savedProgressions.keys}');
    print('Progression chords: ${savedProgressions[name]}');
    setState(() {
      currentProgressionName = name;
      chords = List.from(savedProgressions[name]!);
    });
    print('Loaded chords: $chords');
  }

  void createNewProgression() async {
    final nameController = TextEditingController(text: 'New Progression');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Progression'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Progression Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && !savedProgressions.containsKey(result)) {
      setState(() {
        savedProgressions[result] = [{'key': 'C', 'type': 'major'}];
        currentProgressionName = result;
        chords = List.from(savedProgressions[result]!);
      });
    }
  }

  void renameProgression() async {
    final nameController = TextEditingController(text: currentProgressionName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Progression'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Progression Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentProgressionName) {
      if (savedProgressions.containsKey(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A progression with that name already exists')),
        );
        return;
      }
      setState(() {
        savedProgressions[result] = savedProgressions[currentProgressionName]!;
        savedProgressions.remove(currentProgressionName);
        currentProgressionName = result;
      });
    }
  }

  void deleteProgression() async {
    if (savedProgressions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the last progression')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Progression'),
        content: Text('Are you sure you want to delete "$currentProgressionName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        savedProgressions.remove(currentProgressionName);
        currentProgressionName = savedProgressions.keys.first;
        chords = List.from(savedProgressions[currentProgressionName]!);
      });
    }
  }

  void duplicateProgression() async {
    final nameController = TextEditingController(text: '$currentProgressionName (Copy)');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duplicate Progression'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'New Progression Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Duplicate'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && !savedProgressions.containsKey(result)) {
      setState(() {
        savedProgressions[result] = List.from(chords);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "$result"')),
      );
    }
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
              onPressed: () async {
                await saveSettings();
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
                    
                    // Progression Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chord Progressions',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'new':
                                createNewProgression();
                                break;
                              case 'rename':
                                renameProgression();
                                break;
                              case 'duplicate':
                                duplicateProgression();
                                break;
                              case 'delete':
                                deleteProgression();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'new', child: Row(children: [Icon(Icons.add), SizedBox(width: 8), Text('New')])),
                            PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Rename')])),
                            PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Duplicate')])),
                            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Progression selector
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Active Progression',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        isDense: true,
                      ),
                      value: currentProgressionName,
                      isExpanded: true,
                      items: savedProgressions.keys
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name, style: TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          loadProgression(newValue);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Chord editing section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chords',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
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
                                  flex: 3,
                                  child: SegmentedButton<String>(
                                    showSelectedIcon: false,
                                    style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ),
                                    segments: KeyCenter.values
                                        .map((k) {
                                          // Get just the sharp name (first part before /)
                                          final displayName = k.name.contains('/') 
                                              ? k.name.split('/')[0]
                                              : k.name;
                                          return ButtonSegment<String>(
                                            value: k.name,
                                            label: Text(displayName,
                                                style: TextStyle(fontSize: 11)),
                                          );
                                        })
                                        .toList(),
                                    selected: {chords[index]['key']!},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      updateChord(index, newSelection.first,
                                          chords[index]['type']!);
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                
                                // Type selector
                                Expanded(
                                  flex: 2,
                                  child: SegmentedButton<String>(
                                    showSelectedIcon: false,
                                    style: ButtonStyle(
                                      padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ),
                                    segments: ChordType.values
                                        .map((t) {
                                          // Abbreviate chord type names
                                          String abbrev;
                                          switch (t.name) {
                                            case 'major':
                                              abbrev = 'Maj';
                                              break;
                                            case 'minor':
                                              abbrev = 'Min';
                                              break;
                                            case 'diminished':
                                              abbrev = 'Dim';
                                              break;
                                            default:
                                              abbrev = t.name;
                                          }
                                          return ButtonSegment<String>(
                                            value: t.name,
                                            label: Text(abbrev,
                                                style: TextStyle(fontSize: 12)),
                                          );
                                        })
                                        .toList(),
                                    selected: {chords[index]['type']!},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      updateChord(index, chords[index]['key']!,
                                          newSelection.first);
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
