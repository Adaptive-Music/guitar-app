import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/keyNote.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'dart:math';

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
      // Clear all existing touches and stop all notes
      _touchPositions.clear();
      for (var key in keyNoteKeys) {
        key.currentState?.stopNote();
      }
      // Recreate keys for new scale length
      setState(() {
        keyNoteKeys = List.generate(
          (widget.scale.length + 1) * 2,
          (index) => GlobalKey<KeyNoteState>(),
        );
      });
    }
  }

  void handleTouch() {
    for (var i = 0; i < keyNoteKeys.length; i++) {
      if (keyNoteKeys[i].currentState != null) {
        keyNoteKeys[i].currentState!.checkTouches(_touchPositions);
      }
    }
  }

  void launchConfetti(int pointer) async {
    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) return;
    
    final RenderBox renderBox = overlay.context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    
    while (_touchPositions.keys.contains(pointer)) {
      final Offset position = _touchPositions[pointer]!;
      Confetti.launch(
        context,
        options: ConfettiOptions(
          x: position.dx / size.width,
          y: position.dy / size.height,
          startVelocity: 3,
          spread: 360,
          particleCount: 6,
          decay: 1.0,
          ticks: 50,
          gravity: 0,
          scalar: 3.0,
        ),
        particleBuilder: (index) => Emoji(
          emoji: ['♩', '♪', '♫', '♬', '𝄞', '𝄢'][index % 6],
          textStyle: TextStyle(
            color: defaultColors[Random().nextInt(defaultColors.length)],
            fontSize: 30,
          )
        ),
      );
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          _touchPositions[event.pointer] = event.position;
          launchConfetti(event.pointer);
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
    int maxButtons = ((keyNoteKeys.length) ~/ 2) - 1;
    return Expanded(
      child: Row(
        children: [
          ...List.generate(
            widget.scale.length > maxButtons ? maxButtons : widget.scale.length,
            (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SizedBox.expand(
                      child: KeyNote(
                          key: keyNoteKeys[keyOffset + index],
                          startNote: startNote,
                          index: index,
                          scale: widget.scale,
                          playingMode: widget.playingMode,
                          sfID: widget.sfID,
                          midiController: widget.midiController)),
                ),
              );
            }
          ),
          if (keyOffset + widget.scale.length < keyNoteKeys.length)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox.expand(
                    child: KeyNote(
                        key: keyNoteKeys[keyOffset + widget.scale.length],
                        startNote: startNote + 12,  // One octave higher
                        index: 0,  // Same scale degree as first button
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
