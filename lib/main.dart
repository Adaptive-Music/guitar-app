import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Buttons',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: Scaffold(
        appBar: AppBar(
          title: Text('Full Screen 2 Rows of 7 Buttons'),
        ),
        body: Column(
          children: [
            buildButtonRow(1, 7),
            buildButtonRow(8, 14),
          ],
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
              child: SizedBox.expand(
                child: ElevatedButton(
                  onPressed: () {
                    print('Button ${start + index} pressed');
                  },
                  child: Text('Button ${start + index}'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero, // Ensures no extra padding
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
