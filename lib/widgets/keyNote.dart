import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_application_1/special/enums.dart';
 

class KeyNote extends StatefulWidget {
  final int startNote;
  final int index;
  final Scale scale;

  final PMode playingMode;


  final int sfID;
  final MidiPro midiController;

  const KeyNote({super.key, required this.startNote, required this.sfID, required this.midiController, 
  required this.playingMode, required this.index, required this.scale});
  

  @override
  State<KeyNote> createState() => _KeyNoteState();
}

class _KeyNoteState extends State<KeyNote> {

  List<int> notes = [];

  bool playing = false;

  void playNote() {

    for (var i = 0; i  < notes.length; i++) {
      widget.midiController.playNote(key: notes[i], velocity: 64, sfId: widget.sfID);
    }
    
    setState(() {
      playing = true;
    });
  }

  void stopNote() {

    for (var i = 0; i  < notes.length; i++) {
      widget.midiController.stopNote(key: notes[i], sfId: widget.sfID);
    }
    
    setState(() {
      playing = false;
    });
  }

  void packNotes(){
    int rootNote = widget.startNote + widget.scale.intervals[widget.index];
    if (widget.playingMode.name == 'Single Note') {
      notes = [ rootNote ];
    } else if (widget.playingMode.name == 'Power Chord') {
      int fifthNote = rootNote + 5;
      int lowerRoot = rootNote - 12;
      notes = [ lowerRoot,
                fifthNote,
                rootNote, 
              ];
    } else {
      int thirdPos = (widget.index + 2) % 7;
      int fifthPos = (widget.index + 4) % 7;
      int thirdNote = widget.index > thirdPos ? widget.startNote + widget.scale.intervals[thirdPos] + 12 : widget.startNote + widget.scale.intervals[thirdPos];
      int fifthNote = widget.index > fifthPos ? widget.startNote + widget.scale.intervals[fifthPos] + 12 : widget.startNote + widget.scale.intervals[fifthPos];
      notes = [ rootNote, 
                thirdNote,
                fifthNote,
              ];
    }
  }

  @override

  void initState() {
    super.initState();
    packNotes();
  }


  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => {
        playNote(),
        print('Button ${notes} pressed'),
        },
      onTap: () => {
        stopNote(),
        print('Button ${notes} let go (onTap)'),
      },
      // onPanUpdate: (_) => {
      //   print('Button ${widget.note} (onUpdate)')
      // },
      onPanCancel: () => {
        stopNote(),
        print('Button ${notes} let go (onPanCancel)'),
      },
      onPanEnd: (_) => {
        stopNote(),
        print('Button ${notes} let go (onPanEnd)'),
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
        child: Text('Button ${widget.scale.intervals[widget.index]}'),
      ),
    );
    
    
  }
}