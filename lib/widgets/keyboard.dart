import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/keyNote.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class KeyBoard extends StatefulWidget {
  final int sfID;
  final MidiPro midiController;

  final int keyHarmony;
  final List<int> scale;
  final int octave;
  final String playingMode;

  const KeyBoard(
      {super.key,
      required this.keyHarmony,
      required this.octave,
      required this.scale,
      required this.sfID,
      required this.midiController,
      required this.playingMode});

  @override
  State<KeyBoard> createState() => _KeyBoardState();
}

class _KeyBoardState extends State<KeyBoard> {
  late List<GlobalKey<KeyNoteState>> keyNoteKeys;
  final Map<int, Offset> _touchPositions = {};

  @override
  void initState() {
    super.initState();
    keyNoteKeys = List.generate(
      (widget.scale.length + 1) * 2,  // Added +1 for the extra button in each row
      (index) => GlobalKey<KeyNoteState>(),
    );
  }

  @override
  void didUpdateWidget(covariant KeyBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scale.length != widget.scale.length) {
      // Recreate keys when scale length changes
      setState(() {
        keyNoteKeys = List.generate(
          (widget.scale.length + 1) * 2,
          (index) => GlobalKey<KeyNoteState>(),
        );
      });
    }
  }

  void handleTouch() {
    for (GlobalKey<KeyNoteState> key in keyNoteKeys) {
      key.currentState!.checkTouches(_touchPositions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          _touchPositions[event.pointer] = event.position;
          handleTouch();
        });
      },
      onPointerMove: (PointerMoveEvent event) {
        setState(() {
          _touchPositions[event.pointer] = event.position;
          handleTouch();
        });
      },
      onPointerUp: (PointerUpEvent event) {
        setState(() {
          _touchPositions.remove(event.pointer);
          handleTouch();
        });
      },
      onPointerCancel: (PointerCancelEvent event) {
        setState(() {
          _touchPositions.remove(event.pointer);
          handleTouch();
        });
      },
      child: Column(children: [
        buildButtonRow(widget.octave + widget.keyHarmony, 0),
        buildButtonRow(widget.octave - 12 + widget.keyHarmony, widget.scale.length + 1),
      ]),
    );
  }

  Widget buildButtonRow(int startNote, int keyOffset) {
    return Expanded(
      child: Row(
        children: [
          ...List.generate(widget.scale.length, (index) {
            final keyIndex = keyOffset + index;
            if (keyIndex >= keyNoteKeys.length) return const SizedBox(); // Safety check
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox.expand(
                    child: KeyNote(
                        key: keyNoteKeys[keyIndex],
                        startNote: startNote,
                        index: index,
                        scale: widget.scale,
                        playingMode: widget.playingMode,
                        sfID: widget.sfID,
                        midiController: widget.midiController)),
              ),
            );
          }),
          // Add the octave-up button with safety check
          if (keyOffset + widget.scale.length < keyNoteKeys.length)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox.expand(
                    child: KeyNote(
                        key: keyNoteKeys[keyOffset + widget.scale.length],
                        startNote: startNote + 12,
                        index: 0,
                        scale: widget.scale,
                        playingMode: widget.playingMode,
                        sfID: widget.sfID,
                        midiController: widget.midiController)),
              ),
            ),
        ],
      ),
    );
  }
}
