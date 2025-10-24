import 'package:flutter_application_1/special/enums.dart';

class Chord {
  // Represents the notes in a chord.
  final List<int> notes;
  Chord(this.rootKey, this.type) : notes = _buildChordNotes(rootKey, type);
  final KeyCenter rootKey;
  final ChordType type;

  String getName() {
    // Humanize the chord type enum name: add spaces between camelCase and capitalize words
    String humanize(String s) {
      if (s.isEmpty) return s;
      final withSpaces = s.replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
      return withSpaces[0].toUpperCase() + withSpaces.substring(1);
    }

    final typeLabel = humanize(type.name);
    return '${rootKey.name} $typeLabel';
  }
  
  static _buildChordNotes(KeyCenter rootKey, ChordType type) {
    final int root = rootKey.key;
    final int base = 36;

    // Use the intervals defined on ChordType to build voicings.
    // Intervals are relative to the root (in semitones), e.g. [0,4,7] for major,
    // [0,4,7,10] for dominant 7th, etc.
    final List<int> tones = List<int>.from(type.intervals)..sort();
    final int len = tones.length;

    int toneAt(int idx) => tones[idx % len];

    // Build a 6-note voicing across low/mid/high registers.
    // Layout (relative to root):
    //  - String 0: root
    //  - String 1: prefer the fifth (or next available tone)
    //  - String 2: root + 12
    //  - String 3: third (or next available) + 12
    //  - String 4: if seventh exists use it + 12, else fifth/next tone + 12
    //  - String 5: root + 24
    final List<int> rel = [
      toneAt(0),                              // root
      (len >= 3 ? tones[2] : toneAt(1)),      // prefer fifth if present
      toneAt(0) + 12,                         // root octave
      (len >= 2 ? tones[1] : toneAt(0)) + 12, // third (or next)
      (len >= 4
          ? tones[3]
          : (len >= 3 ? tones[2] : toneAt(1))) + 12, // seventh if present
      toneAt(0) + 24,                         // two octaves root
    ];

    return rel.map((note) => root + note + base).toList();
  } 
}