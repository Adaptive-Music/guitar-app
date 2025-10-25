import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/chord.dart';

class GuitarStrings extends StatefulWidget {
  final Chord? currentChord;
  
  const GuitarStrings({super.key, this.currentChord});

  @override
  State<GuitarStrings> createState() => GuitarStringsState();
}

class GuitarStringsState extends State<GuitarStrings> {
  // Track which strings are currently illuminated (0-5 for strings 1-6)
  final List<bool> _activeStrings = List.generate(6, (_) => false);

  // Store the time when each string was activated for fade effect
  final List<DateTime?> _activationTimes = List.generate(6, (_) => null);

  // Colors for each string (can be customized)
  final List<Color> _stringColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  // Illuminate a specific string (0-5)
  void illuminateString(int stringNumber) {
    if (stringNumber >= 0 && stringNumber < 6) {
      setState(() {
        _activeStrings[stringNumber] = true;
        _activationTimes[stringNumber] = DateTime.now();
      });
    }
  }

  // Turn off a specific string
  void turnOffString(int stringNumber) {
    if (stringNumber >= 0 && stringNumber < 6) {
      setState(() {
        _activeStrings[stringNumber] = false;
        _activationTimes[stringNumber] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = _activeStrings[index];
          final stringColor = _stringColors[index];
          
          // Get note name for this string from current chord
          String noteName = '';
          if (widget.currentChord != null) {
            final midiNote = widget.currentChord!.notes[index];
            final noteNames = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
            noteName = noteNames[midiNote % 12];
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isActive
                      ? stringColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? stringColor : Colors.black,
                    width: isActive ? 3 : 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: stringColor.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // String number label
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? stringColor : Colors.black,
                      ),
                    ),
                    // Note name
                    if (noteName.isNotEmpty)
                      Text(
                        noteName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? stringColor : Colors.black,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Visual string representation
                    Container(
                      height: 4 + ((5 - index) * 0.8), // Thicker for lower strings
                      decoration: BoxDecoration(
                        color: isActive ? stringColor : Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: stringColor.withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
