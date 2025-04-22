import 'package:flutter/material.dart';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CalculatorApp(),
    );
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  final TextEditingController expressionController = TextEditingController(text: "0");
  final TextEditingController resultController = TextEditingController(text: "0");

  void onButtonPressed(String buttonText) {
    log('Button pressed: $buttonText');
    //print('Button pressed: $buttonText');

    // Actual calculator logic will be implemented in the next exercise
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Expression TextField
            TextField(
              controller: expressionController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Result TextField
            TextField(
              controller: resultController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Calculator buttons
            Expanded(
              child: CalculatorButtons(onPressed: onButtonPressed),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    expressionController.dispose();
    resultController.dispose();
    super.dispose();
  }
}

class CalculatorButtons extends StatelessWidget {
  final Function(String) onPressed;

  const CalculatorButtons({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildButtonRow(['AC', 'C', '/', '*']),
        buildButtonRow(['7', '8', '9', '-']),
        buildButtonRow(['4', '5', '6', '+']),
        buildButtonRow(['1', '2', '3', '=']),
        buildLastRow(),
      ],
    );
  }

  Widget buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((text) => buildButton(text)).toList(),
      ),
    );
  }

  Widget buildLastRow() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildButton('0', flex: 2),
          buildButton('.'),
          const Expanded(child: SizedBox()), // Placeholder to maintain grid
        ],
      ),
    );
  }

  Widget buildButton(String text, {int flex = 1}) {
    Color buttonColor;
    if (text == 'AC' || text == 'C') {
      buttonColor = Colors.redAccent;
    } else if (text == '=' || text == '+' || text == '-' || text == '*' || text == '/') {
      buttonColor = Colors.orange;
    } else {
      buttonColor = Colors.grey.shade300;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => onPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}