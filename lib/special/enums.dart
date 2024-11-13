enum Scale {
  major(name: 'Major', intervals: [0, 2, 4, 5, 7, 9, 11]),
  minor(name: 'Minor', intervals: [0, 2, 3, 5, 7, 8, 10]),
  harmonicMinor(name: 'Minor', intervals: [0, 2, 3, 5, 7, 8, 11]),
  pentatonicMinor(name: 'Pentatonic Minor', intervals: [0, 3, 5, 7, 10]),
  pentatonicMajor(name: 'Pentatonic Major', intervals: [0, 3, 5, 7, 10]);

  const Scale({
    required this.name,
    required this.intervals,
  });

  final String name;
  final List<int> intervals;
}

enum PMode {
  sNote(name: 'Single Note'),
  tChord(name: 'Triad Chord'),
  pChord(name: 'Power Chord'),
  tArp(name: 'Arpeggio');

  const PMode({
    required this.name,
  });

  final String name;
  
}


enum KeyCenter {
  cNat(name: 'C', key: 0),
  cSh(name: 'C# / Db', key: 1),
  dNat(name: 'D', key: 2),
  dSh(name: 'D# / Eb', key: 3),
  eNat(name: 'E', key: 4),
  fNat(name: 'F', key: 5),
  fSh(name: 'F# / Gb', key: 6),
  gNat(name: 'G', key: 7),
  gSh(name: 'G# / Ab', key: 8),
  aNat(name: 'A', key: 9),
  aSh(name: 'A# / Bb', key: 10),
  bNat(name: 'B', key: 11);

  const KeyCenter({
    required this.name,
    required this.key,
  });

  final String name;
  final int key;
}



enum Octave {
  zero(name: '0', number: 12),
  one(name: '1', number:24),
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
}