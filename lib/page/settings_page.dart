import 'package:flutter/material.dart';
import 'package:flutter_application_1/special/enums.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final int sfID;
  final SharedPreferences? prefs;

  const SettingsPage({super.key, required this.prefs, required this.sfID});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool prefLoaded = false;

  late Instrument selectedInstrument;

  extractSettings() {
    selectedInstrument = Instrument.values
        .firstWhere((e) => e.name == widget.prefs!.getString('instrument')!);

    print("Instrument: $selectedInstrument");

    setState(() {
      prefLoaded = true;
      print('Pref Loaded');
    });
  }

  Future<void> saveSettings() async {
    setState(() {
      widget.prefs?.setString('instrument', selectedInstrument.name);

      MidiPro().selectInstrument(
          sfId: widget.sfID,
          bank: selectedInstrument.bank,
          program: selectedInstrument.program);

      print('settings saved');
    });
  }

  @override
  void initState() {
    super.initState();
    extractSettings();
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
