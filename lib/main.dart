import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,  // This removes the debug banner
      home: Scaffold(
        appBar: AppBar(
          title: Text('Music App Screen Demo'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: List.generate(7, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0), // Adds space between buttons
                      child: SizedBox.expand(
                        child: ElevatedButton(
                          onPressed: () {
                            print('Button ${index + 1} pressed');
                          },
                          child: Text('Button ${index + 1}'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Ensures no extra padding
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Row(
                children: List.generate(7, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0), // Adds space between buttons
                      child: SizedBox.expand(
                        child: ElevatedButton(
                          onPressed: () {
                            print('Button ${index + 8} pressed');
                          },
                          child: Text('Button ${index + 8}'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Ensures no extra padding
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
