import 'package:flutter_application_1/special/enums.dart';

class Chord {
  // Represents the notes in a chord.
  final List<int> notes;
  Chord(this.rootKey, this.type) : notes = _buildChordNotes(rootKey, type);
  final KeyCenter rootKey;
  final ChordType type;

  String getName() {
    return '${rootKey.name} ${type.name}';
  }
  
  static _buildChordNotes(KeyCenter rootKey, ChordType type) {
    final int root = rootKey.key;
    
    // Define the intervals for each chord type (root, third, fifth)
    int third = type == ChordType.major ? 4 : 3;
    int fifth = type == ChordType.diminished ? 6 : 7;

    List<int> chordNotes = [0, fifth, 12, third + 12, fifth + 12, 24];
    return chordNotes.map((note) => root + note + 36).toList();
  } 
}