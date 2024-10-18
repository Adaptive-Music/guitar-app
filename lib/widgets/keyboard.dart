import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/widgets/KeyNote.dart';
import 'package:flutter_application_1/special/enums.dart';

class KeyBoard extends StatefulWidget {
  final int keyHarmony;
  final Scale scale;
  final int octave;
  final int sfID;
  final MidiPro midiController;
  const KeyBoard({super.key, required this.keyHarmony, required this.octave,  required this.scale, required this.sfID, required this.midiController});
  

  @override
  State<KeyBoard> createState() => _KeyBoardState();
}

class _KeyBoardState extends State<KeyBoard> {

  
  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        buildButtonRow(widget.octave + widget.keyHarmony), // First row of buttons (MIDI notes 60-66)
        buildButtonRow(widget.octave - 12 + widget.keyHarmony), // Second row of buttons (MIDI notes 67-73)
      ]
    );
  }


  Widget buildButtonRow( int startNote ) {

    return Expanded(
      child: Row(
        children: List.generate(widget.scale.intervals.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Adds space between buttons
              child: SizedBox.expand(
                child: KeyNote(note: startNote + widget.scale.intervals[index], sfID: widget.sfID, midiController: widget.midiController)
              ),
            ),
          );
        }),
      ),
    );
  }


}