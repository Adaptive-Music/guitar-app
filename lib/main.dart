import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MidiPro _midi = MidiPro();
  int sfID = 0;

  @override
  void initState() {
    super.initState();
    loadSoundFont();
    print("loaded");
  }

  // Function to load the SoundFont
  Future<void> loadSoundFont() async {
    sfID = await _midi.loadSoundfont(
      path: 'assets/soundfonts/GeneralUserGS.sf2',
      bank: 0,
      program: 0,
    );
        // _midi.prepare(sf2: sf2);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Scaffold(
        appBar: AppBar(
          title: Text('Full Screen 2 Rows of 7 Buttons'),
        ),
        body: Column(
          children: [
            buildButtonRow(60, 66), // First row of buttons (MIDI notes 60-66)
            buildButtonRow(67, 73), // Second row of buttons (MIDI notes 67-73)
          ],
        ),
      ),
    );
  }

  // Function to build a row of buttons
  Widget buildButtonRow(int start, int end) {
    return Expanded(
      child: Row(
        children: List.generate(end - start + 1, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Adds space between buttons
              child: SizedBox.expand(
                child: ElevatedButton(
                  onPressed: () {
                    _midi.playNote(key: start + index, velocity: 64, sfId: sfID); // Play corresponding MIDI note
                    print('Button ${start + index} pressed');
                  },
                  child: Text('Button ${start + index}'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero, // Ensures no extra padding
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    // _midi.unload(); // Unload the SoundFont when the widget is disposed
    super.dispose();
  }
}
