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
  // Intensity per string from MIDI velocity (0.0 - 1.0)
  final List<double> _stringIntensities = List.generate(6, (_) => 0.0);

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

  // Illuminate a specific string (0-5) with velocity-based intensity
  void illuminateString(int stringNumber, [int velocity = 127]) {
    if (stringNumber >= 0 && stringNumber < 6) {
      setState(() {
        _activeStrings[stringNumber] = true;
        // Clamp velocity and convert to 0..1
  final v = velocity.clamp(0, 127);
  _stringIntensities[stringNumber] = v / 127.0;
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
          final intensity = _stringIntensities[index]; // 0..1
          
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
                      ? stringColor.withOpacity(
                          // Base 0.2 with boost up to +0.5, capped at 0.7
                          (0.2 + 0.5 * intensity).clamp(0.0, 0.7),
                        )
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? stringColor : Colors.black,
                    // Base 2.0 + up to +2.0, capped at 3.0
                    width: isActive ? (2.0 + 2.0 * intensity).clamp(2.0, 3.0) : 2.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            // Opacity capped at 0.7
                            color: stringColor.withOpacity((0.3 + 0.5 * intensity).clamp(0.0, 0.7)),
                            // Blur capped at 10
                            blurRadius: (6 + 10 * intensity).clamp(0.0, 10.0),
                            // Spread capped at 1.5
                            spreadRadius: (1 + 2 * intensity).clamp(0.0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // String number label
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stroke layer for readability
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = Colors.black,
                          ),
                        ),
                        // Fill layer
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Note name
                    if (noteName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          noteName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    // Visual string representation
                    Container(
                      height: 4 + ((5 - index) * 0.8), // Thicker for lower strings
                      decoration: BoxDecoration(
            color: isActive
              ? stringColor.withOpacity((0.5 + 0.5 * intensity).clamp(0.0, 0.8))
                            : Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: stringColor.withOpacity((0.5 + 0.4 * intensity).clamp(0.0, 0.7)),
                                  blurRadius: (4 + 6 * intensity).clamp(0.0, 7.0),
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
