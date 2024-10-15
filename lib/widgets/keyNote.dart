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
  bool playing = false;

  void playNote() {
    widget.midiController.playNote(key: widget.note, velocity: 64, sfId: widget.sfID);
    setState(() {
      playing = true;
    });
  }

  void stopNote() {
    widget.midiController.stopNote(key: widget.note, sfId: widget.sfID);
    setState(() {
      playing = false;
    });
  }

  @override

  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => {
        playNote(),
        print('Button ${widget.note} pressed'),
        },
      onTap: () => {
        stopNote(),
        print('Button ${widget.note} let go (onTap)'),
      },
      // onPanUpdate: (_) => {
      //   print('Button ${widget.note} (onUpdate)')
      // },
      onPanCancel: () => {
        stopNote(),
        print('Button ${widget.note} let go (onPanCancel)'),
      },
      onPanEnd: (_) => {
        stopNote(),
        print('Button ${widget.note} let go (onPanEnd)'),
      },
      // onTapCancel: () => {
      //   stopNote(),
      //   print('Button ${widget.note} let go (canceled)'),
      // },
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