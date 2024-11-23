import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/widgets/KeyNote.dart';

class KeyBoard extends StatefulWidget {
  final int sfID;
  final MidiPro midiController;

  final int keyHarmony;
  final List<int> scale;
  final int octave;
  final String playingMode;

  const KeyBoard({super.key, required this.keyHarmony, required this.octave,  required this.scale, 
  required this.sfID, required this.midiController, required this.playingMode});
  

  @override
  State<KeyBoard> createState() => _KeyBoardState();
}

class _KeyBoardState extends State<KeyBoard> {
  List<GlobalKey> keyNoteKeys = [];
  final Map<int, Offset> _touchPositions = {};

  @override
  void initState() {
    super.initState();
    keyNoteKeys = List.generate(widget.scale.length * 2, (index) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildButtonRow(widget.octave + widget.keyHarmony, 0), // First row of buttons (MIDI notes 60-66)
        buildButtonRow(widget.octave - 12 + widget.keyHarmony, widget.scale.length), // Second row of buttons (MIDI notes 67-73)
      ]
    );
  }

  Widget buildButtonRow(int startNote, int keyOffset) {
    return Expanded(
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          setState(() {
            _touchPositions[event.pointer] = event.localPosition;
            print("Pointer ${event.pointer} down at ${event.localPosition}");
          });
        },
        onPointerMove: (PointerMoveEvent event) {
          setState(() {
            _touchPositions[event.pointer] = event.localPosition;
            print("Pointer ${event.pointer} moved to ${event.localPosition}");
          });
        },
        onPointerUp: (PointerUpEvent event) {
          setState(() {
            _touchPositions.remove(event.pointer);
            print("Pointer ${event.pointer} up at ${event.localPosition}");
          });
        },
        child: Row(
          children: List.generate(widget.scale.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0), // Adds space between buttons
                child: SizedBox.expand(
                  child: KeyNote(
                    globalKey: keyNoteKeys[keyOffset + index],
                    startNote: startNote,
                    index: index,
                    scale: widget.scale,
                    playingMode: widget.playingMode,
                    sfID: widget.sfID, 
                    midiController: widget.midiController)
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}