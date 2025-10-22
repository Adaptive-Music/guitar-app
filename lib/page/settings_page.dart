import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:input_quantity/input_quantity.dart';

class SettingsPage extends StatefulWidget {
  final int sfID;
  final SharedPreferences? prefs;

  const SettingsPage({super.key, required this.prefs, required this.sfID});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool prefLoaded = false;

  late String selectedKeyHarmony;
  late String selectedPlayingMode;
  late String selectedScale;
  late String selectedOctave;
  late Instrument selectedInstrument;

  // Get the appropriate key name based on the scale
  String getKeyName(KeyCenter keyCenter) {
    final scale = Scale.values.firstWhere((s) => s.name == selectedScale);
    int keyValue = keyCenter.key;
    bool useFlats = scale.shouldUseFlats(keyValue);

    // For natural notes, return as is
    if (!keyCenter.name.contains('/')) return keyCenter.name;

    // For accidentals, split and return appropriate version
    final parts = keyCenter.name.split('/');
    return useFlats ? parts[1] : parts[0];
  }

  // Use KeyCenter enum values for key harmony selection with appropriate accidentals
  List<String> get selectionKeyHarmony =>
      KeyCenter.values.map((k) => getKeyName(k)).toList();

  late List<String> selectionPlayingMode;

  // Use Scale enum values for scale selection
  List<String> get selectionScale => Scale.values.map((s) => s.name).toList();

  extractSettings() {
    selectedKeyHarmony = widget.prefs!.getString('keyHarmony')!;
    selectedScale = widget.prefs!.getString('currentScale')!;
    selectedOctave = widget.prefs!.getString('octave')!;
    selectedPlayingMode = widget.prefs!.getString('playingMode')!;
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);

    print("Key Harmony: $selectedKeyHarmony");
    print("Scale: $selectedScale");
    print("Octave: $selectedOctave");
    print("Instrument: $selectedInstrument");
    print("Playing Mode: $selectedPlayingMode");

    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  loadSelections() {
    // Get the Scale enum value from the selected scale name
    final scale = Scale.values.firstWhere((s) => s.name == selectedScale);

    if (scale == Scale.pentatonicMajor || scale == Scale.pentatonicMinor) {
      setState(() {
        selectionPlayingMode = ['Single Note', 'Power Chord'];
        selectedPlayingMode = selectedPlayingMode == 'Triad Chord'
            ? 'Single Note'
            : selectedPlayingMode;
      });
    } else {
      setState(() {
        selectionPlayingMode = ['Single Note', 'Triad Chord', 'Power Chord'];
      });
    }
  }

  Future<void> saveSettings() async {
    setState(() {
      widget.prefs?.setString('keyHarmony', selectedKeyHarmony);
      widget.prefs?.setString('currentScale', selectedScale);
      widget.prefs?.setString('octave', selectedOctave);
      widget.prefs?.setString('playingMode', selectedPlayingMode);
      widget.prefs?.setString('instrument', selectedInstrument.name);

      MidiPro().selectInstrument(
          sfId: widget.sfID,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);

      print('settings saved');
    });
  }

  // Build a minus button with a vertical divider on its right edge
  Widget _buildMinusBtn(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          right: BorderSide(color: cs.outline, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.remove, color: cs.primary, size: 18),
    );
  }

  // Build a plus button with a vertical divider on its left edge
  Widget _buildPlusBtn(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: BorderSide(color: cs.outline, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.add, color: cs.primary, size: 18),
    );
  }

  Widget _buildGlobalSettings(BuildContext context) {
    final isTall = MediaQuery.of(context).size.aspectRatio < (16 / 9);

    final keySelector = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Key',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        SegmentedButton<String>(
          segments: KeyCenter.values
              .map((k) => ButtonSegment<String>(
                    value: k.name,
                    label: Text(getKeyName(k), style: TextStyle(fontSize: 13)),
                    // Disable the selection icon
                    icon: SizedBox.shrink(),
                  ))
              .toList(),
          selected: {selectedKeyHarmony},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              selectedKeyHarmony = newSelection.first;
            });
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding:
                MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 3)),
          ),
          showSelectedIcon: false,
        ),
      ],
    );

    final scaleSelector = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Scale',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        SegmentedButton<String>(
          segments: selectionScale
              .map((value) => ButtonSegment<String>(
                    value: value,
                    label: Text(
                        isTall
                            ? value
                            : value
                                .replaceAll('Harmonic', 'Harm.')
                                .replaceAll('Pentatonic', 'Pent.'),
                        style: TextStyle(fontSize: 13)),
                    // Disable the selection icon
                    icon: SizedBox.shrink(),
                  ))
              .toList(),
          selected: {selectedScale},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              selectedScale = newSelection.first;
            });
            loadSelections();
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding:
                MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 3)),
          ),
          showSelectedIcon: false,
        ),
      ],
    );

    if (isTall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          keySelector,
          SizedBox(height: 12),
          scaleSelector,
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(flex: 6, child: keySelector),
          SizedBox(width: 12),
          Expanded(flex: 4, child: scaleSelector),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    extractSettings();
    loadSelections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Disable default back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Cancel',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                saveSettings();
                Navigator.pop(context);
              },
              tooltip: 'Save and Close',
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Global settings row
                    _buildGlobalSettings(context),

                    Divider(height: 16),

                    // Instrument settings
                    DropdownButtonFormField<Instrument>(
                      decoration: InputDecoration(
                        labelText: 'Instrument',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        isDense: true,
                      ),
                      initialValue: selectedInstrument,
                      isExpanded: true,
                      items: Instrument.values
                          .map((instrument) => DropdownMenuItem(
                                value: instrument,
                                child: Text(instrument.name,
                                    style: TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedInstrument = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    // Octave
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('Octave',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        InputQty.int(
                          minVal: 2,
                          maxVal: 7,
                          initVal: int.tryParse(selectedOctave) ?? 4,
                          steps: 1,
                          onQtyChanged: (val) {
                            setState(() {
                              selectedOctave = val.toString();
                            });
                          },
                          qtyFormProps: QtyFormProps(
                            enableTyping: false,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          decoration: QtyDecorationProps(
                            orientation: ButtonOrientation.horizontal,
                            isBordered: false,
                            borderShape: BorderShapeBtn.none,
                            qtyStyle: QtyStyle.classic,
                            btnColor: Theme.of(context).colorScheme.primary,
                            fillColor: Theme.of(context).colorScheme.surface,
                            minusBtn: SizedBox(
                                width: 36,
                                height: 32,
                                child: _buildMinusBtn(context)),
                            plusBtn: SizedBox(
                                width: 36,
                                height: 32,
                                child: _buildPlusBtn(context)),
                            minusButtonConstrains:
                                BoxConstraints.tightFor(width: 36, height: 32),
                            plusButtonConstrains:
                                BoxConstraints.tightFor(width: 36, height: 32),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Play Mode
                    Text('Play Mode',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    SegmentedButton<String>(
                      segments: selectionPlayingMode
                          .map((value) => ButtonSegment<String>(
                                value: value,
                                label:
                                    Text(value, style: TextStyle(fontSize: 13)),
                                icon: SizedBox.shrink(),
                              ))
                          .toList(),
                      selected: {selectedPlayingMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          selectedPlayingMode = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(horizontal: 3)),
                      ),
                      showSelectedIcon: false,
                    ),

                    // Commented out sections preserved but not active
                    // SizedBox(height: 16),
                    // DropdownButtonFormField<String>(
                    //   decoration: InputDecoration(labelText: 'Visuals'),
                    //   value: selectedVisuals,
                    //   items: selectionVisuals
                    //       .map((value) => DropdownMenuItem(
                    //             value: value,
                    //             child: Text(value),
                    //           ))
                    //       .toList(),
                    //   onChanged: (newValue) {
                    //     setState(() {
                    //       selectedVisuals = newValue!;
                    //     });
                    //   },
                    // ),
                    // SizedBox(height: 16),
                    // DropdownButtonFormField<String>(
                    //   decoration:
                    //       InputDecoration(labelText: 'Keyboard Symbols'),
                    //   value: selectedSymbols,
                    //   items: selectionSymbols
                    //       .map((value) => DropdownMenuItem(
                    //             value: value,
                    //             child: Text(value),
                    //           ))
                    //       .toList(),
                    //   onChanged: (newValue) {
                    //     setState(() {
                    //       selectedSymbols = newValue!;
                    //     });
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
