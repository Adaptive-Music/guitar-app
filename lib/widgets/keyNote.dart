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
  final int frogVolume;
  final int appVolume;

  const KeyNote({
      super.key,
      required this.startNote1,
      required this.startNote2,
      required this.sfID1,
      required this.sfID2,
      required this.midiController,
      required this.midiCommand,
      required this.playingMode1,
      required this.playingMode2,
      required this.index,
      required this.scale,
      required this.frogVolume,
      required this.appVolume});

  @override
  State<KeyNote> createState() => KeyNoteState();
}

class KeyNoteState extends State<KeyNote> {
  List<int> notes1 = [];
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
    print("Playing notes: $notes1 with volume: ${widget.frogVolume}");
    for (var i = 0; i < notes1.length; i++) {
      widget.midiController
          .playNote(key: notes1[i], velocity: widget.frogVolume, sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = true;
    });
  }

  void stopNote() {
    print("Stopping notes: $notes1");
    for (var i = 0; i < notes1.length; i++) {
      widget.midiController.stopNote(key: notes1[i], sfId: widget.sfID1);
    }
    setState(() {
      isPlayingSound = false;
    });
  }


  void ledOn() {
    HapticFeedback.mediumImpact();  // Add haptic feedback
    // Send LED note on with frog volume for LED brightness
    sendNoteOn(60 + Scale.major.intervals[widget.index]);
    for (var i = 0; i < notes2.length; i++) {
      widget.midiController
          .playNote(key: notes2[i], velocity: widget.appVolume, sfId: widget.sfID2);
    }
    print("Playing notes $notes2 with volume: ${widget.appVolume}");
    setState(() {
      isLedOn = true;
    });
  }

  void ledOff() {
    // widget.midiController.stopNote(key: notes[i], sfId: widget.sfID);
    sendNoteOff(60 + Scale.major.intervals[widget.index]);
    for (var i = 0; i < notes2.length; i++) {
      widget.midiController.stopNote(key: notes2[i], sfId: widget.sfID2);
    }
    print("Stopping notes $notes2");
    setState(() {
      isLedOn = false;
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

  void packNotes(int selection) {
    if (widget.index >= widget.scale.length) {
      setState(() {
        if (selection == 1) {
          notes1 = [];
        } else {
          notes2 = [];
        }
      });
      return;
    }
    
    int startNote = selection == 1 ? widget.startNote1 : widget.startNote2;
    String playingMode = selection == 1 ? widget.playingMode1 : widget.playingMode2;
    int rootNote = startNote + widget.scale[widget.index];

    List<int> newNotes = [];
    if (playingMode == 'Single Note') {
      newNotes = [rootNote];
    } else if (playingMode == 'Power Chord') {
      int fifthNote = rootNote + 7;  // Perfect fifth is 7 semitones
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
      
      int startNoteForChord = selection == 1 ? widget.startNote1 : widget.startNote2;
      
      int thirdNote = widget.index > thirdPos
          ? startNoteForChord + widget.scale[thirdPos] + 12
          : startNoteForChord + widget.scale[thirdPos];
      
      int fifthNote = widget.index > fifthPos
          ? startNoteForChord + widget.scale[fifthPos] + 12
          : startNoteForChord + widget.scale[fifthPos];
          
      newNotes = [
        rootNote,
        thirdNote,
        fifthNote,
        rootNote + 12,
      ];
    }
    
    setState(() {
      if (selection == 1) {
        notes1 = newNotes;
      } else {
        notes2 = newNotes;
      }
    });

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
