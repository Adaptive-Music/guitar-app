import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class KeyNote extends StatefulWidget {
  final int startNote;
  final int index;
  final List<int> scale;

  final String playingMode;

  final int sfID;
  final MidiPro midiController;

  const KeyNote(
      {super.key,
      required this.startNote,
      required this.sfID,
      required this.midiController,
      required this.playingMode,
      required this.index,
      required this.scale});

  @override
  State<KeyNote> createState() => KeyNoteState();
}

class KeyNoteState extends State<KeyNote> {
  List<int> notes = [];
  late Rect bounds;
  bool playing = false;

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
    if (isTouched && !playing) {
      playNote();
    } else if (!isTouched && playing) {
      stopNote();
    }

  }

  void playNote() {
    for (var i = 0; i < notes.length; i++) {
      widget.midiController
          .playNote(key: notes[i], velocity: 64, sfId: widget.sfID);
    }

    setState(() {
      playing = true;
    });
  }

  void stopNote() {
    for (var i = 0; i < notes.length; i++) {
      widget.midiController.stopNote(key: notes[i], sfId: widget.sfID);
    }

    setState(() {
      playing = false;
    });
  }

  void packNotes() {
    if (widget.index >= widget.scale.length) {
      setState(() {
        notes = [];
      });
      return;
    }
    
    int rootNote = widget.startNote + widget.scale[widget.index];
    if (widget.playingMode == 'Single Note') {
      setState(() {
        notes = [rootNote];
      });
    } else if (widget.playingMode == 'Power Chord') {
      int fifthNote = rootNote + 5;
      int lowerRoot = rootNote - 12;
      setState(() {
        notes = [
          lowerRoot,
          fifthNote,
          rootNote,
        ];
      });
    } else {
      int thirdPos = (widget.index + 2) % 7;
      int fifthPos = (widget.index + 4) % 7;
      int thirdNote = widget.index > thirdPos
          ? widget.startNote + widget.scale[thirdPos] + 12
          : widget.startNote + widget.scale[thirdPos];
      int fifthNote = widget.index > fifthPos
          ? widget.startNote + widget.scale[fifthPos] + 12
          : widget.startNote + widget.scale[fifthPos];
      setState(() {
        notes = [
          rootNote,
          thirdNote,
          fifthNote,
          rootNote + 12,
        ];
      });
    }

    print("Key - Scale: ${widget.scale}");
    print("Key - Playing Mode: ${widget.playingMode}");
    print("Key settings loaded");
  }

  @override
  void didUpdateWidget(covariant KeyNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.playingMode != widget.playingMode) ||
        (oldWidget.startNote != widget.startNote) ||
        (oldWidget.index != widget.index) ||
        (oldWidget.scale != widget.scale) ||
        (oldWidget.sfID != widget.sfID)) {
      packNotes();
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
        backgroundColor: playing ? Colors.yellow : Colors.blue,
        padding: EdgeInsets.zero, // Ensures no extra padding
      ),
      onPressed: () {},
      child: Text(getMidiNoteName(widget.startNote + widget.scale[widget.index])),
    );
  }
}
