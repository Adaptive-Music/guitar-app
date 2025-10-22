import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class KeyNote extends StatefulWidget {
  final int startNote1;
  final int index;
  final Scale scale;

  final String playingMode1;

  final int sfID1;
  final MidiPro midiController;
  final MidiCommand midiCommand;
  final int frogVolume;

  const KeyNote(
      {super.key,
      required this.startNote1,
      required this.sfID1,
      required this.midiController,
      required this.midiCommand,
      required this.playingMode1,
      required this.index,
      required this.scale,
      required this.frogVolume});

  @override
  State<KeyNote> createState() => KeyNoteState();
}

class KeyNoteState extends State<KeyNote> {
  List<int> notes1 = [];
  late Rect bounds;
  bool isPlayingSound = false; // When frog button pressed, sound is played

  static List<Map<String, dynamic>> symbolData = [
    {'symbol': '★', 'color': Colors.yellow, 'size': 28.0}, // star
    {'symbol': '▲', 'color': Colors.purple, 'size': 28.0}, // triangle
    {
      'symbol': '♥',
      'color': Colors.red,
      'size': Platform.isAndroid ? 20.0 : 28.0
    }, // heart
    {
      'symbol': '◆',
      'color': Colors.orange,
      'size': Platform.isAndroid ? 33.0 : 28.0
    }, // diamond
    {'symbol': '■', 'color': Colors.blue, 'size': 28.0}, // square
    {
      'symbol': '●',
      'color': Colors.lightGreen,
      'size': Platform.isAndroid ? 36.0 : 28.0
    }, // circle
    {
      'symbol': '🌙',
      'color': Colors.yellow,
      'size': Platform.isAndroid ? 20.0 : 28.0
    }, // moon
    {
      'symbol': '☀️',
      'color': Colors.yellow,
      'size': Platform.isAndroid ? 24.0 : 28.0
    }, // sun
  ];

  @override
  void initState() {
    super.initState();
    packNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateBounds();
    });
  }

  void updateBounds() {
    if (!mounted) return;
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset topLeft = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      bounds = topLeft & size;
    }
  }

  void checkTouches(Map<int, Offset> touchPositions) {
    bool isTouched = touchPositions.values.any((position) {
      return bounds.contains(position);
    });
    if (isTouched && !isPlayingSound) {
      playNote();
      print('Button ${widget.index} touched');
    } else if (!isTouched && isPlayingSound) {
      stopNote();
      print('Button ${widget.index} released');
    }
  }

  void playNote() {
    HapticFeedback.mediumImpact(); // Add haptic feedback
    // Send LED note on with frog volume for LED brightness
    sendNoteOn(60 + Scale.major.intervals[widget.index]);
    print("Playing notes: $notes1 with volume: ${widget.frogVolume}");
    for (var i = 0; i < notes1.length; i++) {
      widget.midiController.playNote(
          key: notes1[i], velocity: widget.frogVolume, sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = true;
    });
  }

  void stopNote() {
    sendNoteOff(60 + Scale.major.intervals[widget.index]);
    print("Stopping notes: $notes1");
    for (var i = 0; i < notes1.length; i++) {
      widget.midiController.stopNote(key: notes1[i], sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = false;
    });
  }

  void sendNoteOn(note) {
    final noteOn = Uint8List.fromList([0x90, note, widget.frogVolume]);
    widget.midiCommand.sendData(noteOn);
    print("Note: $note with LED brightness: ${widget.frogVolume}");
  }

  void sendNoteOff(note) {
    final noteOff = Uint8List.fromList([0x80, note, 0]);
    widget.midiCommand.sendData(noteOff);
    print(note);
  }

  void packNotes() {
    if (widget.index >= widget.scale.intervals.length) {
      setState(() {
        notes1 = [];
      });
      return;
    }

    int startNote = widget.startNote1;
    String playingMode = widget.playingMode1;
    int rootNote = startNote + widget.scale.intervals[widget.index];

    List<int> newNotes = [];
    if (playingMode == 'Single Note') {
      newNotes = [rootNote];
    } else if (playingMode == 'Power Chord') {
      int fifthNote = rootNote + 7; // Perfect fifth is 7 semitones
      int upperRoot = rootNote + 12;
      newNotes = [
        rootNote,
        fifthNote,
        upperRoot,
      ];
    } else {
      // Triad Chord
      int thirdPos = (widget.index + 2) % 7;
      int fifthPos = (widget.index + 4) % 7;

      int startNoteForChord = widget.startNote1;

      int thirdNote = widget.index > thirdPos
          ? startNoteForChord + widget.scale.intervals[thirdPos] + 12
          : startNoteForChord + widget.scale.intervals[thirdPos];

      int fifthNote = widget.index > fifthPos
          ? startNoteForChord + widget.scale.intervals[fifthPos] + 12
          : startNoteForChord + widget.scale.intervals[fifthPos];

      newNotes = [
        rootNote,
        thirdNote,
        fifthNote,
        rootNote + 12,
      ];
    }

    setState(() {
      notes1 = newNotes;
    });

    // print("Key - Scale: ${widget.scale}");
    // print("Key - Playing Mode: ${widget.playingMode}");
    // print("Key settings loaded");
  }

  @override
  void didUpdateWidget(covariant KeyNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.playingMode1 != widget.playingMode1) ||
        (oldWidget.startNote1 != widget.startNote1) ||
        (oldWidget.index != widget.index) ||
        (oldWidget.scale != widget.scale) ||
        (oldWidget.sfID1 != widget.sfID1)) {
      packNotes();
    }
  }

  String getMidiNoteName(int midiNote) {
    final sharpNoteNames = [
      'C',
      'C♯',
      'D',
      'D♯',
      'E',
      'F',
      'F♯',
      'G',
      'G♯',
      'A',
      'A♯',
      'B'
    ];
    final flatNoteNames = [
      'C',
      'D♭',
      'D',
      'E♭',
      'E',
      'F',
      'G♭',
      'G',
      'A♭',
      'A',
      'B♭',
      'B'
    ];

    final note = midiNote % 12;
    final scaleRoot = widget.startNote1 % 12;

    // Use the Scale enum's method to determine whether to use flats
    bool useFlats = widget.scale.shouldUseFlats(scaleRoot);

    return useFlats ? flatNoteNames[note] : sharpNoteNames[note];
  }

  @override
  Widget build(BuildContext context) {
    // Update bounds whenever widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateBounds();
    });
    // Get the symbol data for this button
    final symbolInfo = widget.index < symbolData.length
        ? symbolData[widget.index]
        : {
            'symbol': '●',
            'color': Colors.grey,
            'size': 24.0
          }; // fallback for any extra buttons

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPlayingSound ? Colors.yellowAccent : Colors.lightBlue,
        padding: EdgeInsets.zero, // Ensures no extra padding
        splashFactory: NoSplash.splashFactory,
        side: BorderSide(
          color: Colors.black54,
          width: 2.0,
        ),
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          Container(
            height: 40, // Fixed height for symbol section
            padding: EdgeInsets.all(4.0),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Create outline by placing copies in multiple positions around the symbol
                for (var offset in [
                  // Main outline positions
                  Offset(-1.5, 0),
                  Offset(1.5, 0),
                  Offset(0, -1.5),
                  Offset(0, 1.5),
                  // Diagonal positions
                  Offset(-1.1, -1.1),
                  Offset(1.1, -1.1),
                  Offset(-1.1, 1.1),
                  Offset(1.1, 1.1),
                ])
                  Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.8),
                        BlendMode.srcATop,
                      ),
                      child: Text(
                        symbolInfo['symbol'] as String,
                        style: TextStyle(
                          fontSize: symbolInfo['size'] as double,
                          fontFamily: 'Roboto',
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                // Main symbol
                Text(
                  symbolInfo['symbol'] as String,
                  style: TextStyle(
                    fontSize: symbolInfo['size'] as double,
                    fontFamily: 'Roboto',
                    color: symbolInfo['color'] as Color,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 28, // Fixed height for consistent alignment
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outline for note name
                Text(
                  getMidiNoteName(
                      widget.startNote1 + widget.scale.intervals[widget.index]),
                  style: TextStyle(
                    fontSize: 20,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3.0
                      ..color = Colors.black,
                    // fontWeight: FontWeight.bold,
                    height: 1, // Ensure consistent line height
                  ),
                ),
                // Main note name
                Text(
                  getMidiNoteName(
                      widget.startNote1 + widget.scale.intervals[widget.index]),
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    // fontWeight: FontWeight.bold,
                    height: 1, // Ensure consistent line height
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
