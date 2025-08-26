import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_application_1/widgets/keyNote.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'dart:math';

class KeyBoard extends StatefulWidget {
  final int sfID1;
  final int sfID2;
  final MidiPro midiController;
  final MidiCommand midiCommand;

  final int keyHarmony;
  final List<int> scale;
  final int octave1;
  final int octave2;
  final String playingMode1;
  final String playingMode2;
  final int frogVolume;
  final int appVolume;

  const KeyBoard({
      super.key,
      required this.keyHarmony,
      required this.octave1,
      required this.octave2,
      required this.scale,
      required this.sfID1,
      required this.sfID2,
      required this.midiController,
      required this.midiCommand,
      required this.playingMode1,
      required this.playingMode2,
      required this.frogVolume,
      required this.appVolume});

  @override
  State<KeyBoard> createState() => _KeyBoardState();
}

class _KeyBoardState extends State<KeyBoard> {
  late List<GlobalKey<KeyNoteState>> keyNoteKeys;
  final Map<int, Offset> _touchPositions = {};
  final Random _random = Random();
  late final ConfettiOptions _confettiOptions;
  final List<String> _musicEmojis = ['♩', '♪', '♫', '♬'];

  @override
  void initState() {
    super.initState();
    keyNoteKeys = List.generate(
      (widget.scale.length + 1) * 2,
      (index) => GlobalKey<KeyNoteState>(),
    );
    initMidiListening();
    _confettiOptions = ConfettiOptions(
      flat: true,
      startVelocity: 4,
      spread: 360,
      particleCount: 1,
      decay: 1.0,
      ticks: 40,
      gravity: 0,
    );
  }

  @override
  void didUpdateWidget(covariant KeyBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scale.length != widget.scale.length) {
      // Clear all existing touches and stop all notes
      _touchPositions.clear();
    for (var key in keyNoteKeys) {
        key.currentState?.ledOff();
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
    final fontSize = 50.0;
    
    while (_touchPositions.keys.contains(pointer)) {
      final position = _touchPositions[pointer]!;
      
      Confetti.launch(
        context,
        options: _confettiOptions.copyWith(
          x: (position.dx - fontSize / 2) / size.width,
          y: (position.dy - fontSize / 2) / size.height,
        ),
        particleBuilder: (index) => Emoji(
          emoji: _musicEmojis[_random.nextInt(_musicEmojis.length)],
          textStyle: TextStyle(
            color: defaultColors[_random.nextInt(defaultColors.length)],
            fontSize: 50,
            height: 1.1
          )
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void initMidiListening() async {
    // Connect to a device first
    // Example: connectToDevice(device) where 'device' is from midiCommand.devices

    // Listen for incoming MIDI data
    widget.midiCommand.onMidiDataReceived?.listen((MidiPacket packet) {
      // packet.data is a Uint8List containing raw MIDI bytes
      Uint8List data = packet.data;

      // Example: interpret a Note On (0x90) message
      if (data.isNotEmpty) {
        int status = data[0];
        int note = data.length > 1 ? data[1] : 0;
        int velocity = data.length > 2 ? data[2] : 0;

        print("Received MIDI message: status=$status, note=$note, velocity=$velocity");

        // Determine which frog button has been pressed (0-7)
        int index = note == 72 ? 7 : Scale.major.intervals.indexOf(note - 60);
        if ((status & 0xF0) == 0x90 && velocity > 0) {
          keyNoteKeys[index].currentState?.playNote();
          // widget.midiController
          // .playNote(key: note, velocity: 100, sfId: widget.sfID);
          print("Index: $index, Note On: $note with velocity $velocity");
        } else if ((status & 0xF0) == 0x80 || ((status & 0xF0) == 0x90 && velocity == 0)) {
          keyNoteKeys[index].currentState?.stopNote();
          print("Index: $index, Note Off: $note");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          _touchPositions[event.pointer] = event.position;
          // launchConfetti(event.pointer);
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
        buildButtonRow(widget.octave1 + widget.keyHarmony, widget.octave2 + widget.keyHarmony, 0),
        // buildButtonRow(widget.octave - 12 + widget.keyHarmony, widget.scale.length + 1),
      ]),
    );
  }

  Widget buildButtonRow(int startNote1, int startNote2, int keyOffset) {
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
                          startNote1: startNote1,
                          startNote2: startNote2,
                          index: index,
                          scale: widget.scale,
                          playingMode1: widget.playingMode1,
                          playingMode2: widget.playingMode2,
                          sfID1: widget.sfID1,
                          sfID2: widget.sfID2,
                          midiController: widget.midiController,
                          midiCommand: widget.midiCommand,
                          frogVolume: widget.frogVolume,
                          appVolume: widget.appVolume)),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
