import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class KeyNote extends StatefulWidget {
  final int startNote1;
  final int startNote2;
  final int index;
  final List<int> scale;

  final String playingMode1;
  final String playingMode2;

  final int sfID1;
  final int sfID2;
  final MidiPro midiController;
  final MidiCommand midiCommand;

  const KeyNote(
      {super.key,
      required this.startNote1,
      required this.startNote2,
      required this.sfID1,
      required this.sfID2,
      required this.midiController,
      required this.midiCommand,
      required this.playingMode1,
      required this.playingMode2,
      required this.index,
      required this.scale});

  @override
  State<KeyNote> createState() => KeyNoteState();
}

class KeyNoteState extends State<KeyNote> {
  List<int> notes = [];
  List<int> notes2 = [];
  late Rect bounds;
  bool isLedOn = false; // When key pressed on app, frog LED lights up
  bool isPlayingSound = false; // When frog button pressed, sound is played

  @override
  void initState() {
    super.initState();
    packNotes(1);
    packNotes(2);
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
    if (isTouched && !isLedOn) {
      ledOn();
      print('Button ${widget.index} touched');
    } else if (!isTouched && isLedOn) {
      ledOff();
      print('Button ${widget.index} released');
    }

  }

  void playNote() {
    print("Playing notes: $notes");
    for (var i = 0; i < notes.length; i++) {
      widget.midiController
          .playNote(key: notes[i], velocity: 64, sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = true;
    });
  }

  void stopNote() {
    print("Stopping notes: $notes");
    for (var i = 0; i < notes.length; i++) {
      widget.midiController.stopNote(key: notes[i], sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = false;
    });
  }


  void ledOn() {
    HapticFeedback.mediumImpact();  // Add haptic feedback
    // widget.midiController
    //     .playNote(key: notes[i], velocity: 64, sfId: widget.sfID);
    sendNoteOn(60 + Scale.major.intervals[widget.index]);

    setState(() {
      isLedOn = true;
    });
  }

  void ledOff() {
    // widget.midiController.stopNote(key: notes[i], sfId: widget.sfID);
    sendNoteOff(60 + Scale.major.intervals[widget.index]);

    setState(() {
      isLedOn = false;
    });
  }


  

  void sendNoteOn(note) {
    final noteOn = Uint8List.fromList([0x90, note, 100]);
    widget.midiCommand.sendData(noteOn);
    print(note);
  }

  void sendNoteOff(note) {
    final noteOff = Uint8List.fromList([0x80, note, 0]);
    widget.midiCommand.sendData(noteOff);
    print(note);
  }

  void packNotes(int selection) {
    List<int> noteList = selection == 1 ? notes : notes2;
    if (widget.index >= widget.scale.length) {
      setState(() {
        noteList = [];
      });
      return;
    }
    
    int startNote = selection == 1 ? widget.startNote1 : widget.startNote2;
    String playingMode = selection == 1 ? widget.playingMode1 : widget.playingMode2;
    int rootNote = startNote + widget.scale[widget.index];

    if (playingMode == 'Single Note') {
      setState(() {
        notes = [rootNote];
      });
    } else if (playingMode == 'Power Chord') {
      int fifthNote = rootNote + 5;
      int upperRoot = rootNote + 12;
      setState(() {
        notes = [
          rootNote,
          fifthNote,
          upperRoot,
        ];
      });
    } else {
      int thirdPos = (widget.index + 2) % 7;
      int fifthPos = (widget.index + 4) % 7;
      int thirdNote = widget.index > thirdPos
          ? widget.startNote1 + widget.scale[thirdPos] + 12
          : widget.startNote1 + widget.scale[thirdPos];
      int fifthNote = widget.index > fifthPos
          ? widget.startNote1 + widget.scale[fifthPos] + 12
          : widget.startNote1 + widget.scale[fifthPos];
      setState(() {
        notes = [
          rootNote,
          thirdNote,
          fifthNote,
          rootNote + 12,
        ];
      });
    }

    // print("Key - Scale: ${widget.scale}");
    // print("Key - Playing Mode: ${widget.playingMode}");
    // print("Key settings loaded");
  }

  @override
  void didUpdateWidget(covariant KeyNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.playingMode1 != widget.playingMode1) ||
        (oldWidget.playingMode2 != widget.playingMode2) ||
        (oldWidget.startNote1 != widget.startNote1) ||
        (oldWidget.startNote2 != widget.startNote2) ||
        (oldWidget.index != widget.index) ||
        (oldWidget.scale != widget.scale) ||
        (oldWidget.sfID1 != widget.sfID1) ||
        (oldWidget.sfID2 != widget.sfID2)) {
      packNotes(1);
      packNotes(2);
    }
  }

  String getMidiNoteName(int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return noteNames[midiNote % 12];
  }

  @override
  Widget build(BuildContext context) {
    // Update bounds whenever widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateBounds();
    });
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
          isPlayingSound && isLedOn ? Colors.lightGreenAccent :
          isPlayingSound ? Colors.orangeAccent :
          isLedOn ? Colors.yellowAccent :
          Colors.lightBlue,
        padding: EdgeInsets.zero, // Ensures no extra padding
        splashFactory: NoSplash.splashFactory,
      ),
      onPressed: () {},
      child: Text(getMidiNoteName(widget.startNote1 + widget.scale[widget.index])),
    );
  }
}
