import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/settings_page.dart';
import 'package:flutter_application_1/widgets/chord.dart';
import 'package:flutter_application_1/widgets/guitar_strings.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Configuration classes to group related parameters
class ChordState {
  final Chord currentChord;
  final int currentChordIndex;
  final List<Chord> chordList;
  final String progressionName;

  const ChordState({
    required this.currentChord,
    required this.currentChordIndex,
    required this.chordList,
    required this.progressionName,
  });
}

class ChordCallbacks {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Function(int) onSelect;
  final VoidCallback onUpdate;

  const ChordCallbacks({
    required this.onNext,
    required this.onPrevious,
    required this.onSelect,
    required this.onUpdate,
  });
}

class MidiConfig {
  final SharedPreferences? prefs;
  final int sfID;
  final MidiDevice? selectedDevice;
  final GlobalKey<GuitarStringsState> guitarStringsKey;
  final MidiPro midiPlayer;

  const MidiConfig({
    required this.prefs,
    required this.sfID,
    required this.selectedDevice,
    required this.guitarStringsKey,
    required this.midiPlayer,
  });
}

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
  late int sfID;
  final GlobalKey<GuitarStringsState> _guitarStringsKey =
      GlobalKey<GuitarStringsState>();

  SharedPreferences? _prefs;
  Instrument selectedInstrument = Instrument.values[0]; // Default value
  int currentChord = 0;
  List<Chord> chords = [];
  String currentProgressionName = '';

  bool _sfLoading = true;
  bool _midiConnecting = false;
  bool _prefLoading = true;

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
    print('Found MIDI devices:');
    for (var device in newMidiDevices ?? []) {
      print(' - ${device.name} (connected: ${device.connected})');
    }
    if (newMidiDevices != null &&
        !newMidiDevices.contains(selectedMidiDevice)) {
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
      if (device.name.contains("TP Guitar") ||
          device.name.contains("MIDI Connector")) {
        print('Connecting to device: ${device.name}');
        if (device.connected) {
          print('Device ${device.name} is already connected.');
          setState(() {
            selectedMidiDevice = device;
            _midiConnecting = false;
          });
          return;
        }
        await _midi_cmd.connectToDevice(device);
        initMidiListening();
        print('Connected to ${device.name}.');
        setState(() {
          selectedMidiDevice = device;
        });
        break;
      }
    }
    if (selectedMidiDevice == null) {
      print('No suitable MIDI device found or connection failed.');
      selectedMidiDevice = null;
    }
    setState(() {
      _midiConnecting = false;
    });
  }

  void initMidiListening() async {
    // Connect to a device first
    // Example: connectToDevice(device) where 'device' is from midiCommand.devices

    // Listen for incoming MIDI data
    _midi_cmd.onMidiDataReceived?.listen((MidiPacket packet) {
      // packet.data is a Uint8List containing raw MIDI bytes
      Uint8List data = packet.data;

      // Example: interpret a Note On (0x90) message
      if (data.isNotEmpty) {
        int status = data[0];
        int note = data.length > 1 ? data[1] : 0;
        int velocity = data.length > 2 ? data[2] : 0;

        print("Received MIDI message: status=$status, note=$note, velocity=$velocity");

        // Determine which string based on note number
        int stringNumber = getStringNumberFromNote(note);
        print("String Number: $stringNumber");

        // Illuminate the corresponding guitar string on Note On
        if ((status & 0xF0) == 0x90 && velocity > 0) {
          // Note On
          _guitarStringsKey.currentState?.illuminateString(stringNumber, velocity);
          // Play the MIDI note from the current chord
          int chordNote = chords[currentChord].notes[stringNumber];
          _midi.playNote(key: chordNote, velocity: velocity, sfId: sfID);
          
        } else if ((status & 0xF0) == 0x80 ||
            ((status & 0xF0) == 0x90 && velocity == 0)) {
          // Note Off (either explicit 0x80 or Note On with velocity 0)
          _guitarStringsKey.currentState?.turnOffString(stringNumber);
          // Stop the MIDI note from the current chord
          int chordNote = chords[currentChord].notes[stringNumber];
          _midi.stopNote(key: chordNote, sfId: sfID);
        }
      }
    });
  }

  int getStringNumberFromNote(int note) {
    // Should work with standard or Open C tuning
    if (note < 42)
      return 0;
    else if (note < 47)
      return 1;
    else if (note < 53)
      return 2;
    else if (note < 58)
      return 3;
    else if (note < 63)
      return 4;
    else
      return 5;
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

    if (_prefs?.getString('instrument') == null) {
      _prefs?.setString('instrument', Instrument.values[0].name);
    }

    if (_prefs?.getString('playingMode') == null) {
      _prefs?.setString('playingMode', 'Single Note');
    }

    // Initialize default chords if not set
    if (_prefs?.getStringList('chords') == null) {
      final defaultChords = [
        'C:major',
        'G:major',
        'A:minor',
        'F:major',
      ];
      await _prefs?.setStringList('chords', defaultChords);
    }

    // Load chords from preferences
    _loadChords();

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

  void _loadChords() {
    // Load from the new progression system
    currentProgressionName = _prefs?.getString('currentProgressionName') ?? 'Default';
    final progressionsJson = _prefs?.getString('savedProgressions');
    
    List<Map<String, String>> chordMaps = [];
    
    if (progressionsJson != null) {
      final decoded = json.decode(progressionsJson) as Map<String, dynamic>;
      if (decoded.containsKey(currentProgressionName)) {
        final progression = decoded[currentProgressionName] as List;
        chordMaps = progression.map((chord) {
          return {
            'key': chord['key'] as String,
            'type': chord['type'] as String,
          };
        }).toList();
      }
    }
    
    // Fallback to old 'chords' key for backwards compatibility (only if no progressions found)
    if (chordMaps.isEmpty) {
      final chordStrings = _prefs?.getStringList('chords') ?? [];
      chordMaps = chordStrings.map((chordStr) {
        final parts = chordStr.split(':');
        return {
          'key': parts.length > 0 ? parts[0] : 'C',
          'type': parts.length > 1 ? parts[1] : 'major',
        };
      }).toList();
    }
    
    // Convert to Chord objects
    chords = chordMaps.map((chordMap) {
      final keyCenter = KeyCenter.values.firstWhere(
        (k) => k.name == chordMap['key'],
        orElse: () => KeyCenter.cNat,
      );
      final chordType = ChordType.values.firstWhere(
        (t) => t.name == chordMap['type'],
        orElse: () => ChordType.major,
      );
      
      return Chord(keyCenter, chordType);
    }).toList();
    
    print('Loaded ${chords.length} chords from progression: $currentProgressionName');
  }

  @override
  void initState() {
    super.initState();
    _initPrefs(); // Only call _initPrefs, which will handle loadSoundFont

    // Enable wakelock to prevent screen timeout
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    // Disable wakelock when the app is closed
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  void _stopCurrentChordNotesAndStrings() {
    if (chords.isNotEmpty && currentChord < chords.length) {
      for (int i = 0; i < chords[currentChord].notes.length; i++) {
        _midi.stopNote(key: chords[currentChord].notes[i], sfId: sfID);
        _guitarStringsKey.currentState?.turnOffString(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuitarApp',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Builder(
        builder: (context) {
          if (_sfLoading || _prefLoading || _midiConnecting) {
            // Show a loading screen while waiting for async task to complete
            return const Scaffold(
              body: Center(child: Text('Loading...')),
            );
          }
          return HomeScreen(
            chordState: ChordState(
              currentChord: chords.isNotEmpty ? chords[currentChord] : Chord(KeyCenter.cNat, ChordType.major),
              currentChordIndex: currentChord,
              chordList: chords,
              progressionName: currentProgressionName,
            ),
            callbacks: ChordCallbacks(
              onNext: () {
                setState(() {
                  _stopCurrentChordNotesAndStrings();
                  if (chords.isNotEmpty) {
                    currentChord = (currentChord + 1) % chords.length;
                  }
                });
              },
              onPrevious: () {
                setState(() {
                  _stopCurrentChordNotesAndStrings();
                  if (chords.isNotEmpty) {
                    currentChord = (currentChord - 1 + chords.length) % chords.length;
                  }
                });
              },
              onSelect: (int index) {
                setState(() {
                  _stopCurrentChordNotesAndStrings();
                  currentChord = index;
                });
              },
              onUpdate: () {
                setState(() {
                  _loadChords();
                  // Reset to first chord when returning from settings
                  currentChord = 0;
                });
              },
            ),
            midiConfig: MidiConfig(
              prefs: _prefs,
              sfID: sfID,
              selectedDevice: selectedMidiDevice,
              guitarStringsKey: _guitarStringsKey,
              midiPlayer: _midi,
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ChordState chordState;
  final ChordCallbacks callbacks;
  final MidiConfig midiConfig;

  const HomeScreen({
    super.key,
    required this.chordState,
    required this.callbacks,
    required this.midiConfig,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Make sure wakelock is still enabled when this screen is shown
    WakelockPlus.enable();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Scroll to current chord when it changes
    if (oldWidget.chordState.currentChordIndex != widget.chordState.currentChordIndex) {
      _scrollToCurrentChord();
    }
  }

  void _scrollToCurrentChord() {
    if (_scrollController.hasClients && widget.chordState.chordList.isNotEmpty) {
      // Use ensureVisible for smoother, less jumpy scrolling
      // This only scrolls if the item is not already visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final itemHeight = 56.0 + 1.0; // ListTile height + Divider height
          final targetOffset = widget.chordState.currentChordIndex * itemHeight;
          final viewportHeight = _scrollController.position.viewportDimension;
          final currentOffset = _scrollController.offset;
          
          // Only scroll if the item is outside the visible area
          if (targetOffset < currentOffset || 
              targetOffset > currentOffset + viewportHeight - itemHeight) {
            // Center the item in the viewport
            final centerOffset = targetOffset - (viewportHeight / 2) + (itemHeight / 2);
            final clampedOffset = centerOffset.clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );
            
            _scrollController.animateTo(
              clampedOffset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.midiConfig.selectedDevice == null ? 'Not connected' : widget.chordState.progressionName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Go to Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SettingsPage(prefs: widget.midiConfig.prefs, sfID: widget.midiConfig.sfID)),
              ).then((_) {
                widget.callbacks.onUpdate();
              });
            },
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              nextChord();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              previousChord();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
        children: [
          // Guitar Strings Visualization
          GuitarStrings(
            key: widget.midiConfig.guitarStringsKey,
            currentChord: widget.chordState.currentChord,
            midiPlayer: widget.midiConfig.midiPlayer,
            sfId: widget.midiConfig.sfID,
          ),
          // Keyboard and Chord List
          Expanded(
            child: Row(
              children: [
                // Big Button
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: widget.chordState.currentChord.rootKey.color,
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: nextChord,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: FittedBox(
                                  key: ValueKey<String>('${widget.chordState.currentChord.rootKey.name}-${widget.chordState.currentChord.type.displayName}'),
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Big key label (sharp name only)
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            (widget.chordState.currentChord.rootKey.name.contains('/')
                                                    ? widget.chordState.currentChord.rootKey.name.split('/')[0]
                                                    : widget.chordState.currentChord.rootKey.name),
                                            style: TextStyle(
                                              fontSize: 350,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 15
                                                ..color = Colors.black,
                                            ),
                                          ),
                                          Text(
                                            (widget.chordState.currentChord.rootKey.name.contains('/')
                                                    ? widget.chordState.currentChord.rootKey.name.split('/')[0]
                                                    : widget.chordState.currentChord.rootKey.name),
                                            style: TextStyle(
                                              fontSize: 350,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Smaller chord type display name
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            widget.chordState.currentChord.type.displayName,
                                            style: TextStyle(
                                              fontSize: 72,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 6
                                                ..color = Colors.black,
                                            ),
                                          ),
                                          Text(
                                            widget.chordState.currentChord.type.displayName,
                                            style: TextStyle(
                                              fontSize: 72,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Chord List
                SizedBox(
                  width: 230,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9), // Slightly smaller to fit inside border
                        child: Container(
                          color: Colors.white,
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: widget.chordState.chordList.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey[800],
                            ),
                        itemBuilder: (context, index) {
                          final chord = widget.chordState.chordList[index];
                          final isSelected = index == widget.chordState.currentChordIndex;
                          // Build compact chord label using sharp key name + chord type symbol
                          final keyLabel = chord.rootKey.name.contains('/')
                              ? chord.rootKey.name.split('/')[0]
                              : chord.rootKey.name;
                          final chordLabel = '${keyLabel} ${chord.type.symbol}';
                          final isLastItem = index == widget.chordState.chordList.length - 1;
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? chord.rootKey.color : chord.rootKey.color.withOpacity(0.3),
                              border: isLastItem
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[800]!,
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              // Keep horizontal alignment by reserving space for the indicator
                              minLeadingWidth: 12,
                              leading: SizedBox(
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
                              ),
                              title: isSelected
                                  ? Stack(
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
                                    )
                                  : RichText(
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
                                    ),
                              onTap: () => widget.callbacks.onSelect(index),
                            ),
                          );
                        },
                      ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void nextChord() {
    widget.callbacks.onNext();
  }

  void previousChord() {
    widget.callbacks.onPrevious();
  }
}
