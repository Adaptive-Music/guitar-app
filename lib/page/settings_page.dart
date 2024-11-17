import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';

class SettingsPage extends StatefulWidget {

  final String option1;
  final String option2;
 
  const SettingsPage({super.key, required this.option1, required this.option2});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String option1temp = widget.option1;
  late String option2temp = widget.option2;
  late Scale selectedScale = Scale.major;
  late String selectedOctave = '4';
  late String selectedMode = 'Single Note';
  
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Instrument'),
              value: option1temp,
              items: ['Piano', 'Violin', 'Synthesiser', 'Guitar', 'Drums']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  option1temp = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Key Centre'),
              value: 'C',
              items: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  option2temp = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Scale>(
              decoration: InputDecoration(labelText: 'Scale'),
              value: selectedScale,
              items: Scale.values
                  .map((scale) => DropdownMenuItem(
                        value: scale,
                        child: Text(scale.name),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedScale = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Octave'),
              value: selectedOctave,
              items: ['2', '3', '4', '5', '6', '7']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedOctave = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Keyboard Mode'),
              value: selectedMode,
              items: ['Single Note', 'Triad Chord', 'Power Chord',]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedMode = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Visuals'),
              value: 'Grid',
              items: ['Grid', 'Custom']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {});
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Keyboard Symbols'),
              value: 'Shapes',
              items: ['Shapes', 'Letters', 'Numbers', 'None']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {});
              },
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

