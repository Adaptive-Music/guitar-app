import 'package:flutter/material.dart';

enum Scale {
  major(name: 'Major', intervals: [0, 2, 4, 5, 7, 9, 11, 12]),
  minor(name: 'Minor', intervals: [0, 2, 3, 5, 7, 8, 10, 12]),
  harmonicMinor(name: 'Harmonic Minor', intervals: [0, 2, 3, 5, 7, 8, 11, 12]),
  pentatonicMinor(
      name: 'Pentatonic Minor', intervals: [0, 3, 5, 7, 10, 12, 15, 17]),
  pentatonicMajor(
      name: 'Pentatonic Major', intervals: [0, 4, 5, 7, 11, 12, 16, 17]);

  const Scale({
    required this.name,
    required this.intervals,
  });

  final String name;
  final List<int> intervals;

  // Static method to find intervals by name
  static List<int> getIntervals(String name) {
    return Scale.values.firstWhere((scale) => scale.name == name).intervals;
  }

  // Static method to return scale by name
  static Scale getScale(String name) {
    return Scale.values.firstWhere((scale) => scale.name == name);
  }

  // Determines if a key should use flats based on music theory conventions
  bool shouldUseFlats(int rootNote) {
    // Sharp keys: G(7), D(2), A(9), E(4), B(11)
    // Flat keys: F(5), Bb(10), Eb(3), Ab(8), Db(1)
    // C(0) uses neither

    final flatKeys = [5, 10, 3, 8, 1]; // F, Bb, Eb, Ab, Db

    switch (this) {
      case Scale.major:
        // For major scales, use flats if the root is F or has flats
        return flatKeys.contains(rootNote);

      case Scale.minor:
      case Scale.harmonicMinor:
        // For minor scales, use flats if the relative major would use flats
        // Relative major is 3 semitones up
        final relativeMajor = (rootNote + 3) % 12;
        return flatKeys.contains(relativeMajor);

      case Scale.pentatonicMajor:
        // Follow the same rules as major scale
        return flatKeys.contains(rootNote);

      case Scale.pentatonicMinor:
        // Follow the same rules as minor scale
        final relativeMajor = (rootNote + 3) % 12;
        return flatKeys.contains(relativeMajor);
    }
  }
}

enum KeyCenter {
  cNat(name: 'C', key: 0, color: Colors.red),
  cSh(name: 'C♯/D♭', key: 1, color: Color(0xFFFF7043)),
  dNat(name: 'D', key: 2, color: Colors.orange),
  dSh(name: 'D♯/E♭', key: 3, color: Color(0xFFFFD54F)),
  eNat(name: 'E', key: 4, color: Colors.yellow),
  fNat(name: 'F', key: 5, color: Colors.green),
  fSh(name: 'F♯/G♭', key: 6, color: Color(0xFF26C6DA)),
  gNat(name: 'G', key: 7, color: Colors.lightBlue),
  gSh(name: 'G♯/A♭', key: 8, color: Color(0xFF1E88E5)),
  aNat(name: 'A', key: 9, color: Colors.indigo),
  aSh(name: 'A♯/B♭', key: 10, color: Color(0xFF8E24AA)),
  bNat(name: 'B', key: 11, color: Colors.purple);

  const KeyCenter({
    required this.name,
    required this.key,
    required this.color,
  });

  final String name;
  final int key;
  final Color color;

  String getName(Scale scale) {
    final sharpNoteNames = [
      'C',
      'C♯',
      'D',
      'D♯',
      'E',
      'F',
      'F♯',
      'G',
      'G♯',
      'A',
      'A♯',
      'B'
    ];
    final flatNoteNames = [
      'C',
      'D♭',
      'D',
      'E♭',
      'E',
      'F',
      'G♭',
      'G',
      'A♭',
      'A',
      'B♭',
      'B'
    ];
    if (scale.shouldUseFlats(key)) {
      return flatNoteNames[key % 12];
    } else {
      return sharpNoteNames[key % 12];
    }
  }

  static int getKey(String name) {
    return KeyCenter.values
        .firstWhere((keyCenter) => keyCenter.name == name)
        .key;
  }
}

enum Octave {
  zero(name: '0', number: 12),
  one(name: '1', number: 24),
  two(name: '2', number: 36),
  three(name: '3', number: 48),
  four(name: '4', number: 60),
  five(name: '5', number: 72),
  six(name: '6', number: 84),
  seven(name: '7', number: 96),
  eight(name: '8', number: 108);

  const Octave({
    required this.name,
    required this.number,
  });

  final String name;
  final int number;

  static int getNum(String name) {
    return Octave.values.firstWhere((octave) => octave.name == name).number;
  }
}

enum Instrument {
  piano(bank: 0, program: 2),
  celeste(bank: 0, program: 8),
  synthPad(bank: 0, program: 88),
  vibraphone(bank: 0, program: 11),
  organ(bank: 0, program: 19),
  violin(bank: 0, program: 40),
  cello(bank: 0, program: 42),
  harp(bank: 0, program: 46),
  woodBlock(bank: 0, program: 115),
  acousticGuitar(bank: 0, program: 25),
  electricGuitar(bank: 0, program: 29),
  bass(bank: 0, program: 33),
  slapBass(bank: 0, program: 36),
  flute(bank: 0, program: 73),
  trumpet(bank: 0, program: 56),
  saxophone(bank: 0, program: 64),
  clarinet(bank: 0, program: 71),
  accordion(bank: 0, program: 21),
  harmonica(bank: 0, program: 22),
  drums(bank: 120, program: 0),
  choir(bank: 0, program: 52),
  sitar(bank: 0, program: 104),
  shamisen(bank: 0, program: 106),
  kalimba(bank: 0, program: 108),
  bell(bank: 0, program: 112),
  dog(bank: 1, program: 123),
  ;

  const Instrument({
    required this.bank,
    required this.program,
  });

  final int bank;
  final int program;

  String get name {
    String last = toString().split('.').last;
    last = last.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}');
    return last[0].toUpperCase() + last.substring(1);
  }
}


enum ChordType {
  major(symbol: 'maj', intervals: [0, 4, 7]),
  minor(symbol: 'min', intervals: [0, 3, 7]),
  dominantSeventh(symbol: '7', intervals: [0, 4, 7, 10]),
  majorSeventh(symbol: 'maj7', intervals: [0, 4, 7, 11]),
  minorSeventh(symbol: 'min7', intervals: [0, 3, 7, 10]),
  diminished(symbol: 'dim', intervals: [0, 3, 6]),
  ;

  const ChordType({
    required this.symbol,
    required this.intervals,

  });

  final String symbol;
  final List<int> intervals;

  // Human-friendly name with spaces and capitalization (e.g., "majorSeventh" -> "Major Seventh")
  String get displayName {
    final s = name; // enum case name
    if (s.isEmpty) return s;
    final withSpaces = s.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }
}

