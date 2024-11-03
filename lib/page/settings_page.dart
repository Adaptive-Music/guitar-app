import 'package:flutter/material.dart';


class SettingsPage extends StatefulWidget {

  final String option1;
  final String option2;
 
  const SettingsPage({super.key, required this.option1, required this.option2});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String option1temp = widget.option1;
  late String option2temp = widget.option2;
  
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: option1temp),
              value: option1temp,
              items: ['Option 1A', 'Option 1B', 'Option 1C']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  option1temp = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: option2temp),
              value: option2temp,
              items: ['Option 2A', 'Option 2B', 'Option 2C']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  option2temp = newValue!;
                });
              },
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

