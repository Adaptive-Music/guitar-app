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
  late Map<String, dynamic> savedSongs; // Song name -> {progressions: {progName: [chords]}, order: [progNames]}
  late String currentSongName;
  late String currentProgressionName;
  int? selectedChordIndex;
  int? selectedProgressionIndex;
  int velocityBoost = 0;

  @override
  void initState() {
    super.initState();
    _extractSettings();
    // Select first chord by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chords.isNotEmpty && selectedChordIndex == null) {
        setState(() {
          selectedChordIndex = 0;
        });
      }
    });
  }

  void _extractSettings() {
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);

    // Load current song and progression names
    currentSongName = widget.prefs!.getString('currentSongName') ?? 'Default Song';
    currentProgressionName = widget.prefs!.getString('currentProgressionName') ?? 'Default';

    // Load saved songs structure
    final songsJson = widget.prefs!.getString('savedSongs');
    if (songsJson != null) {
      savedSongs = json.decode(songsJson) as Map<String, dynamic>;
    } else {
      savedSongs = {};
    }

    // Migration from old progressions-only format
    if (savedSongs.isEmpty) {
      final progressionsJson = widget.prefs!.getString('savedProgressions');
      if (progressionsJson != null) {
        // Migrate old progressions into a default song
        final decoded = json.decode(progressionsJson) as Map<String, dynamic>;
        final progressions = <String, List<Map<String, String>>>{};
        decoded.forEach((key, value) {
          final chordsList = (value as List).map((chord) {
            return {
              'key': chord['key'] as String,
              'type': chord['type'] as String,
            };
          }).toList();
          progressions[key] = chordsList;
        });
        savedSongs['Default Song'] = {
          'progressions': progressions,
          'order': progressions.keys.toList(),
        };
        currentSongName = 'Default Song';
      } else {
        // Check if there's old 'chords' data from before the progression system
        final chordStrings = widget.prefs!.getStringList('chords') ?? [];
        if (chordStrings.isNotEmpty) {
          // Migrate old data to Default progression in Default Song
          final defaultChords = chordStrings.map((chordStr) {
            final parts = chordStr.split(':');
            return {
              'key': parts.length > 0 ? parts[0] : 'C',
              'type': parts.length > 1 ? parts[1] : 'major',
            };
          }).toList();
          savedSongs['Default Song'] = {
            'progressions': {'Default': defaultChords},
            'order': ['Default'],
          };
          widget.prefs!.remove('chords');
        } else {
          // True first launch - create default song with default progression
          savedSongs['Default Song'] = {
            'progressions': {
              'Default': [
                {'key': 'C', 'type': 'major'},
                {'key': 'F', 'type': 'major'},
                {'key': 'G', 'type': 'major'},
                {'key': 'A', 'type': 'minor'},
              ]
            },
            'order': ['Default'],
          };
        }
        currentSongName = 'Default Song';
        currentProgressionName = 'Default';
      }
    }

    // Load current song and progression
    if (!savedSongs.containsKey(currentSongName)) {
      currentSongName = savedSongs.keys.first;
    }
    
    final currentSong = savedSongs[currentSongName] as Map<String, dynamic>;
    final progressions = currentSong['progressions'] as Map<String, dynamic>;
    
    if (!progressions.containsKey(currentProgressionName)) {
      currentProgressionName = (currentSong['order'] as List<dynamic>).first.toString();
    }
    
    // Load chords from current progression
    final progressionData = progressions[currentProgressionName] as List;
    chords = progressionData.map((chord) {
      return {
        'key': chord['key'] as String,
        'type': chord['type'] as String,
      };
    }).toList();

    // Set the selected progression index
    final order = (currentSong['order'] as List).cast<String>();
    selectedProgressionIndex = order.indexOf(currentProgressionName);

    // Load velocity boost
    velocityBoost = widget.prefs!.getInt('velocityBoost') ?? 0;

    print("Instrument: $selectedInstrument");
    print("Current Song: $currentSongName");
    print("Current Progression: $currentProgressionName");
    print("Chords: $chords");

    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  Future<void> saveSettings() async {
    try {
      // Save current chords back to current progression
      final currentSong = savedSongs[currentSongName] as Map<String, dynamic>;
      final progressions = currentSong['progressions'] as Map<String, dynamic>;
      progressions[currentProgressionName] = chords.map((chord) => {
        'key': chord['key']!,
        'type': chord['type']!,
      }).toList();

      // Convert to JSON
      final songsJson = json.encode(savedSongs);

      await widget.prefs?.setString('instrument', selectedInstrument.name);
      await widget.prefs?.setString('savedSongs', songsJson);
      await widget.prefs?.setString('currentSongName', currentSongName);
      await widget.prefs?.setString('currentProgressionName', currentProgressionName);
      await widget.prefs?.setInt('velocityBoost', velocityBoost);

      MidiPro().selectInstrument(
          sfId: widget.sfID,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);

      print('settings saved successfully');
      print('Saved song: $currentSongName');
      print('Saved progression: $currentProgressionName');
      print('Saved ${chords.length} chords');
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  // Helper methods for accessing current song data
  Map<String, dynamic> get currentSongProgressions {
    final song = savedSongs[currentSongName] as Map<String, dynamic>;
    return song['progressions'] as Map<String, dynamic>;
  }

  List<String> get currentSongProgressionOrder {
    final song = savedSongs[currentSongName] as Map<String, dynamic>;
    return List<String>.from(song['order']);
  }

  void setCurrentSongProgressionOrder(List<String> order) {
    final song = savedSongs[currentSongName] as Map<String, dynamic>;
    song['order'] = order;
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
    final progressions = currentSongProgressions;
    print('Available progressions: ${progressions.keys}');
    print('Progression chords: ${progressions[name]}');
    setState(() {
      currentProgressionName = name;
      final progressionData = progressions[name] as List;
      chords = progressionData.map((chord) {
        return {
          'key': chord['key'] as String,
          'type': chord['type'] as String,
        };
      }).toList();
      selectedChordIndex = chords.isNotEmpty ? 0 : null; // Select first chord
      selectedProgressionIndex = currentSongProgressionOrder.indexOf(name);
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

    if (result != null && result.isNotEmpty && !currentSongProgressions.containsKey(result)) {
      setState(() {
        final progressions = currentSongProgressions;
        progressions[result] = [{'key': 'C', 'type': 'major'}];
        // Add to order list
        final order = currentSongProgressionOrder;
        order.add(result);
        setCurrentSongProgressionOrder(order);
        currentProgressionName = result;
        chords = [{'key': 'C', 'type': 'major'}];
        selectedProgressionIndex = order.length - 1;
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
      if (currentSongProgressions.containsKey(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A progression with that name already exists')),
        );
        return;
      }
      setState(() {
        final progressions = currentSongProgressions;
        progressions[result] = progressions[currentProgressionName]!;
        progressions.remove(currentProgressionName);
        // Update order list
        final order = currentSongProgressionOrder;
        final index = order.indexOf(currentProgressionName);
        order[index] = result;
        setCurrentSongProgressionOrder(order);
        currentProgressionName = result;
      });
    }
  }

  void deleteProgression() async {
    final progressions = currentSongProgressions;
    if (progressions.length <= 1) {
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
        progressions.remove(currentProgressionName);
        // Update order list
        final order = currentSongProgressionOrder;
        order.remove(currentProgressionName);
        setCurrentSongProgressionOrder(order);
        // Load first remaining progression
        currentProgressionName = order.first;
        final progressionData = progressions[currentProgressionName] as List;
        chords = progressionData.map((chord) {
          return {
            'key': chord['key'] as String,
            'type': chord['type'] as String,
          };
        }).toList();
        selectedProgressionIndex = 0;
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

    if (result != null && result.isNotEmpty && !currentSongProgressions.containsKey(result)) {
      setState(() {
        final progressions = currentSongProgressions;
        progressions[result] = List.from(chords.map((chord) => Map<String, String>.from(chord)));
        // Add to order list
        final order = currentSongProgressionOrder;
        order.add(result);
        setCurrentSongProgressionOrder(order);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "$result"')),
      );
    }
  }

  void reorderProgressions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final order = currentSongProgressionOrder;
      final progression = order.removeAt(oldIndex);
      order.insert(newIndex, progression);
      setCurrentSongProgressionOrder(order);
      
      // Update selection to follow the moved progression
      if (selectedProgressionIndex == oldIndex) {
        selectedProgressionIndex = newIndex;
      } else if (selectedProgressionIndex != null) {
        if (oldIndex < selectedProgressionIndex! && newIndex >= selectedProgressionIndex!) {
          selectedProgressionIndex = selectedProgressionIndex! - 1;
        } else if (oldIndex > selectedProgressionIndex! && newIndex <= selectedProgressionIndex!) {
          selectedProgressionIndex = selectedProgressionIndex! + 1;
        }
      }
    });
  }

  // Song management methods
  void loadSong(String name) {
    setState(() {
      currentSongName = name;
      final song = savedSongs[name] as Map<String, dynamic>;
      final order = List<String>.from(song['order']);
      currentProgressionName = order.first;
      loadProgression(currentProgressionName);
    });
  }

  void createNewSong() async {
    final nameController = TextEditingController(text: 'New Song');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Song'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Song Name'),
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

    if (result != null && result.isNotEmpty && !savedSongs.containsKey(result)) {
      setState(() {
        savedSongs[result] = {
          'progressions': {
            'Default': [{'key': 'C', 'type': 'major'}]
          },
          'order': ['Default'],
        };
        currentSongName = result;
        currentProgressionName = 'Default';
        chords = [{'key': 'C', 'type': 'major'}];
        selectedProgressionIndex = 0;
      });
    }
  }

  void renameSong() async {
    final nameController = TextEditingController(text: currentSongName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Song'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Song Name'),
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

    if (result != null && result.isNotEmpty && result != currentSongName) {
      if (savedSongs.containsKey(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A song with that name already exists')),
        );
        return;
      }
      setState(() {
        savedSongs[result] = savedSongs[currentSongName]!;
        savedSongs.remove(currentSongName);
        currentSongName = result;
      });
    }
  }

  void deleteSong() async {
    if (savedSongs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the last song')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Song'),
        content: Text('Are you sure you want to delete "$currentSongName"?'),
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
        savedSongs.remove(currentSongName);
        currentSongName = savedSongs.keys.first;
        loadSong(currentSongName);
      });
    }
  }

  void duplicateSong() async {
    final nameController = TextEditingController(text: '$currentSongName (Copy)');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duplicate Song'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'New Song Name'),
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

    if (result != null && result.isNotEmpty && !savedSongs.containsKey(result)) {
      setState(() {
        // Deep copy the song
        final originalSong = savedSongs[currentSongName] as Map<String, dynamic>;
        final originalProgressions = originalSong['progressions'] as Map<String, dynamic>;
        final newProgressions = <String, dynamic>{};
        originalProgressions.forEach((key, value) {
          newProgressions[key] = List.from((value as List).map((chord) => Map<String, String>.from(chord)));
        });
        savedSongs[result] = {
          'progressions': newProgressions,
          'order': List<String>.from(originalSong['order']),
        };
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
                            width: 70,
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

  Widget _buildChordListItem(int index) {
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
    
    final keyLabel = keyCenter.name.contains('/')
        ? keyCenter.name.split('/')[0]
        : keyCenter.name;
    final chordLabel = '${keyLabel} ${chordType.symbol}';
    
    return Container(
      key: ValueKey('$index-${chord['key']}-${chord['type']}'),
      decoration: BoxDecoration(
        color: isSelected 
            ? keyCenter.color
            : keyCenter.color.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        minLeadingWidth: 12,
        leading: _buildChordIndicator(isSelected),
        title: _buildChordTitle(index, chordLabel, isSelected),
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
  }

  Widget _buildProgressionListItem(int index) {
    final order = currentSongProgressionOrder;
    final progressionName = order[index];
    final isSelected = selectedProgressionIndex == index;
    
    return Container(
      key: ValueKey('progression-$index-$progressionName'),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[100] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 12,
        leading: SizedBox(
          width: 12,
          child: Center(
            child: isSelected
                ? Icon(Icons.play_arrow, size: 18, color: Colors.blue)
                : const SizedBox.shrink(),
          ),
        ),
        title: Text(
          '${index + 1}. $progressionName',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle, size: 20),
        ),
        onTap: () {
          loadProgression(progressionName);
        },
      ),
    );
  }

  Widget _buildChordIndicator(bool isSelected) {
    return SizedBox(
      width: 12,
      child: Center(
        child: isSelected
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '→',
                    style: TextStyle(
                      fontSize: 20,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.black,
                    ),
                  ),
                  const Text(
                    '→',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildChordTitle(int index, String chordLabel, bool isSelected) {
    if (isSelected) {
      return Stack(
        children: [
          // Stroke layer
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${index + 1}. ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
                TextSpan(
                  text: chordLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Fill layer
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${index + 1}. ',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: chordLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${index + 1}. ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: chordLabel,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Progression list and Chord list taking full vertical space
          SizedBox(
            width: 280,
            child: Column(
              children: [
                // Progression List Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progressions',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: createNewProgression,
                        tooltip: 'Add Progression',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: currentSongProgressionOrder.length * 57.0, // 56 for ListTile + 1 for divider
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        color: Colors.white,
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: currentSongProgressionOrder.length,
                          onReorder: reorderProgressions,
                          itemBuilder: (context, index) => _buildProgressionListItem(index),
                        ),
                      ),
                    ),
                  ),
                ),
                // Chord List Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Chords',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: addChord,
                        tooltip: 'Add Chord',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9), // Slightly smaller to fit inside border
                        child: Container(
                          color: Colors.white,
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: chords.length,
                            onReorder: reorderChords,
                            itemBuilder: (context, index) => _buildChordListItem(index),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          VerticalDivider(width: 1),
          
          // Right side: Song selector, Progression selector, Chord editor, and Instrument selector stacked
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 0. Song Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Song',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: createNewSong,
                              tooltip: 'New Song',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: duplicateSong,
                              tooltip: 'Duplicate Song',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: renameSong,
                              tooltip: 'Rename Song',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: deleteSong,
                              tooltip: 'Delete Song',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Song',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        isDense: true,
                      ),
                      value: currentSongName,
                      isExpanded: true,
                      items: savedSongs.keys
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name, style: TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          loadSong(newValue);
                        }
                      },
                    ),
                    
                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),
                    
                    // 1. Progression Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progression',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: createNewProgression,
                              tooltip: 'New Progression',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: duplicateProgression,
                              tooltip: 'Duplicate Progression',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: renameProgression,
                              tooltip: 'Rename Progression',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: deleteProgression,
                              tooltip: 'Delete Progression',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Progression',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        isDense: true,
                      ),
                      value: currentProgressionName,
                      isExpanded: true,
                      items: currentSongProgressionOrder
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
                    
                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),
                    
                    // 2. Chord Editor Section
                    selectedChordIndex == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('Select a chord from the list to edit',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : Column(
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
                                        icon: Icon(Icons.info_outline),
                                        onPressed: _showChordTypeInfo,
                                        tooltip: 'Chord type info',
                                      ),                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: chords.length > 1
                                            ? () => removeChord(selectedChordIndex!)
                                            : null,
                                        tooltip: 'Remove chord',
                                        color: Colors.red,
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              
                              // Key selector
                              Text('Root Note',
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
                              Text('Type',
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
                    
                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),
                    
                    // 3. Instrument Selector Section
                    Text('Instrument',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(
                        labelText: 'Select Instrument',
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
                    
                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),
                    
                    // 4. Velocity Boost Section
                    Text('Volume Boost',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: velocityBoost.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: velocityBoost.toString(),
                            onChanged: (double value) {
                              setState(() {
                                velocityBoost = value.round();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: 50,
                          child: Text(
                            velocityBoost.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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
