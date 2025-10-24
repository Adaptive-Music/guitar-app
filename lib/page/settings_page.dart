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
  int? selectedChordIndex;

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
      selectedChordIndex = chords.length - 1; // Select the newly added chord
    });
  }

  void removeChord(int index) {
    setState(() {
      if (chords.length > 1) {
        chords.removeAt(index);
        // Update selection
        if (selectedChordIndex != null) {
          if (selectedChordIndex == index) {
            selectedChordIndex = index > 0 ? index - 1 : 0;
          } else if (selectedChordIndex! > index) {
            selectedChordIndex = selectedChordIndex! - 1;
          }
        }
      }
    });
  }

  void updateChord(int index, String key, String type) {
    setState(() {
      chords[index] = {'key': key, 'type': type};
    });
  }

  void reorderChords(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final chord = chords.removeAt(oldIndex);
      chords.insert(newIndex, chord);
      
      // Update selection to follow the moved chord
      if (selectedChordIndex == oldIndex) {
        selectedChordIndex = newIndex;
      } else if (selectedChordIndex != null) {
        if (oldIndex < selectedChordIndex! && newIndex >= selectedChordIndex!) {
          selectedChordIndex = selectedChordIndex! - 1;
        } else if (oldIndex > selectedChordIndex! && newIndex <= selectedChordIndex!) {
          selectedChordIndex = selectedChordIndex! + 1;
        }
      }
    });
  }

  void loadProgression(String name) {
    print('Loading progression: $name');
    print('Available progressions: ${savedProgressions.keys}');
    print('Progression chords: ${savedProgressions[name]}');
    setState(() {
      currentProgressionName = name;
      chords = List.from(savedProgressions[name]!);
      selectedChordIndex = chords.isNotEmpty ? 0 : null; // Select first chord
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

  void _showChordTypeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chord Types'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ChordType.values
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t.displayName,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    extractSettings();
    // Select first chord by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chords.isNotEmpty && selectedChordIndex == null) {
        setState(() {
          selectedChordIndex = 0;
        });
      }
    });
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
          // Top section: Instrument and Progression settings
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  value: selectedInstrument,
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
                SizedBox(height: 16),
                
                // Progression Management Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Progression',
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
                    ),
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
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Main content: Chord list on left, selectors on right
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side: Reorderable chord list
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chords',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: Icon(Icons.add_circle),
                              onPressed: addChord,
                              tooltip: 'Add Chord',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: chords.length,
                          onReorder: reorderChords,
                          itemBuilder: (context, index) {
                            final chord = chords[index];
                            final isSelected = selectedChordIndex == index;
                            final keyCenter = KeyCenter.values.firstWhere(
                              (k) => k.name == chord['key'],
                              orElse: () => KeyCenter.cNat,
                            );
                            final chordType = ChordType.values.firstWhere(
                              (t) => t.name == chord['type'],
                              orElse: () => ChordType.major,
                            );
                            
                            return Container(
                              key: ValueKey('$index-${chord['key']}-${chord['type']}'),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? keyCenter.color.withOpacity(0.3)
                                    : Colors.transparent,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 3)
                                    : Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                              ),
                              child: ListTile(
                                leading: Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                title: Text(
                                  '${chord['key']} ${chordType.displayName}',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(Icons.drag_handle),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedChordIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                VerticalDivider(width: 1),
                
                // Right side: Chord selectors
                Expanded(
                  flex: 3,
                  child: selectedChordIndex == null
                      ? Center(child: Text('Select a chord to edit'))
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Edit Chord ${selectedChordIndex! + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: chords.length > 1
                                              ? () => removeChord(selectedChordIndex!)
                                              : null,
                                          tooltip: 'Remove chord',
                                          color: Colors.red,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.info_outline),
                                          onPressed: _showChordTypeInfo,
                                          tooltip: 'Chord type info',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                
                                // Key selector
                                Text('Key',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                SegmentedButton<String>(
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                      EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                  ),
                                  segments: KeyCenter.values
                                      .map((k) {
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
                                  selected: {chords[selectedChordIndex!]['key']!},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    updateChord(
                                      selectedChordIndex!,
                                      newSelection.first,
                                      chords[selectedChordIndex!]['type']!,
                                    );
                                  },
                                ),
                                SizedBox(height: 24),
                                
                                // Type selector
                                Text('Chord Type',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                SegmentedButton<String>(
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                      EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                  ),
                                  segments: ChordType.values
                                      .map((t) => ButtonSegment<String>(
                                            value: t.name,
                                            label: Text(
                                              t.symbol,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ))
                                      .toList(),
                                  selected: {chords[selectedChordIndex!]['type']!},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    updateChord(
                                      selectedChordIndex!,
                                      chords[selectedChordIndex!]['key']!,
                                      newSelection.first,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
