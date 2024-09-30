import 'package:flutter/cupertino.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false, // This removes the debug banner
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Music App Screen'),
        ),
        child: SafeArea( // Use SafeArea to prevent overlaps with system UI
          child: Column(
            children: [
              buildButtonRow(1, 7),
              buildButtonRow(8, 14),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build a row of buttons
  Widget buildButtonRow(int start, int end) {
    return Expanded(
      child: Row(
        children: List.generate(end - start + 1, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0), // Adds space between buttons
              child: CupertinoButton(
                onPressed: () {
                  print('Button ${start + index} pressed');
                },
                color: CupertinoColors.activeBlue, // Sets button color
                padding: EdgeInsets.zero,
                child: Center( // Center the text within the button
                  child: Text(
                    'Button ${start + index}',
                    style: const TextStyle(fontSize: 16), // Adjust text size as needed
                  ),
                ), // Ensures no extra padding
              ),
            ),
          );
        }),
      ),
    );
  }
}
