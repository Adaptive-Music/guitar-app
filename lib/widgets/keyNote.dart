import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class KeyNote extends StatefulWidget {
  final int note;
  final int sfID;
  final MidiPro midiController;
  const KeyNote({super.key, required this.note, required this.sfID, required this.midiController});

  @override
  State<KeyNote> createState() => _KeyNoteState();
}

class _KeyNoteState extends State<KeyNote> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => {
        widget.midiController.playNote(key: widget.note, velocity: 64, sfId: widget.sfID),
        print('Button ${widget.note} pressed'),
        },
      onTap: () => {
        widget.midiController.stopNote(key: widget.note, sfId: widget.sfID),
        print('Button ${widget.note} let go (onTap)'),
      },
      onTapCancel: () => {
        widget.midiController.stopNote(key: widget.note, sfId: widget.sfID),
        print('Button ${widget.note} let go (canceled)'),
      },
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Ensures no extra padding
        ),
        onPressed: () {},
        child: Text('Button ${widget.note}'),
      ),
    );
    
    
  }
}