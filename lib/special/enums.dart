enum Scale {
  major(name: 'Major', intervals: [0, 2, 4, 5, 7, 9, 11]),
  minor(name: 'Minor', intervals: [0, 3, 5, 7, 10]),
  pentatonicMinor(name: 'Pentatonic Minor', intervals: [0, 3, 5, 7, 10]),
  pentatonicMajor(name: 'Pentatonic Major', intervals: [0, 3, 5, 7, 10]);

  const Scale({
    required this.name,
    required this.intervals,
  });

  final String name;
  final List<int> intervals;
  
}