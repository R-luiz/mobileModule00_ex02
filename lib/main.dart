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
  final TextEditingController expressionController = TextEditingController(
    text: "0",
  );
  final TextEditingController resultController = TextEditingController(
    text: "0",
  );

  // Track calculation state
  String _currentExpression = "0";
  String _currentResult = "0";
  bool _hasOperator = false;
  bool _hasResult = false;

  void onButtonPressed(String buttonText) {
    log('Button pressed: $buttonText');

    setState(() {
      // Handle different button types
      if (buttonText == 'AC') {
        _clearAll();
      } else if (buttonText == 'C') {
        _clearLast();
      } else if (buttonText == '=') {
        _calculateResult();
      } else if (['+', '-', '*', '/'].contains(buttonText)) {
        _handleOperator(buttonText);
      } else if (buttonText == '.') {
        _handleDecimal();
      } else {
        // Handle numeric input
        _handleNumber(buttonText);
      }

      // Update the text controllers
      expressionController.text = _currentExpression;
      resultController.text = _currentResult;
    });
  }

  void _clearAll() {
    _currentExpression = "0";
    _currentResult = "0";
    _hasOperator = false;
    _hasResult = false;
  }

  void _clearLast() {
    if (_currentExpression.length > 1) {
      // Remove the last character
      String lastChar = _currentExpression[_currentExpression.length - 1];
      _currentExpression = _currentExpression.substring(
        0,
        _currentExpression.length - 1,
      );

      // Update the hasOperator flag if we removed an operator
      if (['+', '-', '*', '/'].contains(lastChar)) {
        _hasOperator = false;
      }

      // If we've cleared everything, reset to 0
      if (_currentExpression.isEmpty) {
        _currentExpression = "0";
      }
    } else {
      _currentExpression = "0";
    }

    // Also reset result if we're clearing
    if (_hasResult) {
      _currentResult = "0";
      _hasResult = false;
    }
  }

  void _handleNumber(String number) {
    // If we just calculated a result and now entering a new number
    if (_hasResult) {
      _currentExpression = number;
      _currentResult = "0";
      _hasResult = false;
      _hasOperator = false;
      return;
    }

    // If the current expression is just "0", replace it
    if (_currentExpression == "0") {
      _currentExpression = number;
    } else {
      _currentExpression += number;
    }
  }

  void _handleOperator(String operator) {
    // If we have a result and are continuing with an operation
    if (_hasResult) {
      _currentExpression = _currentResult + operator;
      _currentResult = "0";
      _hasResult = false;
      _hasOperator = true;
      return;
    }

    // Don't allow multiple operators in a row
    if (_hasOperator) {
      // Replace the last operator if the last character is an operator
      String lastChar = _currentExpression[_currentExpression.length - 1];
      if (['+', '-', '*', '/'].contains(lastChar)) {
        _currentExpression =
            _currentExpression.substring(0, _currentExpression.length - 1) +
            operator;
      } else {
        // We have an operator in the middle, calculate intermediate result
        _calculateResult();
        _currentExpression = _currentResult + operator;
        _hasResult = false;
      }
    } else {
      _currentExpression += operator;
      _hasOperator = true;
    }
  }

  void _handleDecimal() {
    // If we just calculated a result, start a new decimal number
    if (_hasResult) {
      _currentExpression = "0.";
      _currentResult = "0";
      _hasResult = false;
      _hasOperator = false;
      return;
    }

    // Check if the last number already has a decimal point
    List<String> parts = _currentExpression.split(RegExp(r'[+\-*/]'));
    String lastPart = parts.last;

    if (!lastPart.contains('.')) {
      // If the last character is an operator, add "0."
      String lastChar = _currentExpression[_currentExpression.length - 1];
      if (['+', '-', '*', '/'].contains(lastChar)) {
        _currentExpression += "0.";
      } else {
        _currentExpression += '.';
      }
    }
  }

  void _calculateResult() {
    // Don't calculate if we already have a result or if there's no operator
    if (_hasResult || !_hasOperator) {
      return;
    }

    try {
      // Ensure the expression doesn't end with an operator
      String expr = _currentExpression;
      String lastChar = expr[expr.length - 1];
      if (['+', '-', '*', '/'].contains(lastChar)) {
        expr = expr.substring(0, expr.length - 1);
      }

      // Parse the expression and calculate the result
      double result = _evaluateExpression(expr);

      // Format the result
      _currentResult = result.toString();
      // Remove trailing zeros for whole numbers
      if (_currentResult.endsWith('.0')) {
        _currentResult = _currentResult.substring(0, _currentResult.length - 2);
      }

      _hasResult = true;
    } catch (e) {
      _currentResult = "Error";
    }
  }

  double _evaluateExpression(String expression) {
    // Simple expression evaluation
    // First, try to find addition or subtraction operations
    int addIndex = expression.lastIndexOf('+');
    int subIndex = expression.lastIndexOf('-');

    // Handle addition and subtraction with the same precedence
    if (addIndex > 0 || subIndex > 0) {
      int lastOpIndex = addIndex > subIndex ? addIndex : subIndex;
      String leftPart = expression.substring(0, lastOpIndex);
      String rightPart = expression.substring(lastOpIndex + 1);

      double leftValue = _evaluateExpression(leftPart);
      double rightValue = double.parse(rightPart);

      if (expression[lastOpIndex] == '+') {
        return leftValue + rightValue;
      } else {
        return leftValue - rightValue;
      }
    }

    // Then, look for multiplication or division
    int mulIndex = expression.lastIndexOf('*');
    int divIndex = expression.lastIndexOf('/');

    if (mulIndex > 0 || divIndex > 0) {
      int lastOpIndex = mulIndex > divIndex ? mulIndex : divIndex;
      String leftPart = expression.substring(0, lastOpIndex);
      String rightPart = expression.substring(lastOpIndex + 1);

      double leftValue = _evaluateExpression(leftPart);
      double rightValue = double.parse(rightPart);

      if (expression[lastOpIndex] == '*') {
        return leftValue * rightValue;
      } else {
        if (rightValue == 0) {
          throw Exception("Division by zero");
        }
        return leftValue / rightValue;
      }
    }

    // If no operations found, it's just a number
    return double.parse(expression);
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
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),

            // Result TextField
            TextField(
              controller: resultController,
              readOnly: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),

            // Calculator buttons
            Expanded(child: CalculatorButtons(onPressed: onButtonPressed)),
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
    } else if (text == '=' ||
        text == '+' ||
        text == '-' ||
        text == '*' ||
        text == '/') {
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
          child: Text(text, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
