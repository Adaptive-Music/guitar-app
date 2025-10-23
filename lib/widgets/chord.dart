import 'package:flutter_application_1/special/enums.dart';

class Chord {
  // Represents the notes in a chord.
  final List<int> notes;
  Chord(this.rootKey, this.type) : notes = _buildChordNotes(rootKey, type);
  final KeyCenter rootKey;
  final ChordType type;
  
  static _buildChordNotes(KeyCenter rootKey, ChordType type) {
    final int root = rootKey.key;
    
    // Define the intervals for each chord type (root, third, fifth)
    final triadIntervals = switch (type) {
      ChordType.major => [0, 4, 7],        // Major: root, major 3rd, perfect 5th
      ChordType.minor => [0, 3, 7],        // Minor: root, minor 3rd, perfect 5th
      ChordType.diminished => [0, 3, 6],   // Dim: root, minor 3rd, diminished 5th
    };
    
    // Create first triad in base octave, then add octave higher (add 12 semitones)
    // Add 36 to shift into a comfortable MIDI range
    final lowerTriad = triadIntervals.map((interval) => (root + interval) % 12 + 36).toList();
    final upperTriad = triadIntervals.map((interval) => root + interval + 12 + 36).toList();
    
    return [...lowerTriad, ...upperTriad];
  } 
}