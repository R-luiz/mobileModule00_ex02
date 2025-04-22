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
    _hasResult = false;
  }

  void _clearLast() {
    if (_currentExpression.length > 1) {
      // Remove the last character
      _currentExpression = _currentExpression.substring(
        0,
        _currentExpression.length - 1,
      );

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
      return;
    }

    // Allow negative numbers at the start of an expression or after another operator
    if (operator == '-' &&
        (_currentExpression == "0" ||
            _currentExpression.endsWith('+') ||
            _currentExpression.endsWith('-') ||
            _currentExpression.endsWith('*') ||
            _currentExpression.endsWith('/'))) {
      if (_currentExpression == "0") {
        _currentExpression = operator;
      } else {
        _currentExpression += operator;
      }
      return;
    }

    // Check if the last character is an operator and replace it
    if (_currentExpression.isNotEmpty) {
      String lastChar = _currentExpression[_currentExpression.length - 1];
      if (['+', '-', '*', '/'].contains(lastChar)) {
        // Don't allow "--" (replace the operator instead)
        _currentExpression =
            _currentExpression.substring(0, _currentExpression.length - 1) +
            operator;
        return;
      }
    }

    // Otherwise, just add the operator
    _currentExpression += operator;
  }

  void _handleDecimal() {
    // If we just calculated a result, start a new decimal number
    if (_hasResult) {
      _currentExpression = "0.";
      _currentResult = "0";
      _hasResult = false;
      return;
    }

    // Find the last number in the expression
    List<String> parts = [];

    // Split by operators, but handle negative numbers correctly
    int startIndex = 0;
    for (int i = 0; i < _currentExpression.length; i++) {
      if (i > 0 && ['+', '*', '/'].contains(_currentExpression[i])) {
        parts.add(_currentExpression.substring(startIndex, i));
        startIndex = i + 1;
      } else if (i > 0 &&
          _currentExpression[i] == '-' &&
          ![
            '0',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '.',
          ].contains(_currentExpression[i - 1])) {
        // This is a negative sign, not subtraction
        // Don't split here
      } else if (i > 0 && _currentExpression[i] == '-') {
        parts.add(_currentExpression.substring(startIndex, i));
        startIndex = i + 1;
      }
    }

    // Add the last part
    parts.add(_currentExpression.substring(startIndex));

    // Check if the last number already has a decimal point
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
    // Don't calculate if we already have a result
    if (_hasResult) {
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
    if (expression.isEmpty) return 0;

    // Parse the expression using the shunting yard algorithm
    try {
      return _calculate(expression);
    } catch (e) {
      log('Error evaluating expression: $e');
      throw Exception("Invalid expression");
    }
  }

  double _calculate(String expression) {
    // Tokenize the expression
    List<String> tokens = _tokenize(expression);

    // Convert to Reverse Polish Notation (postfix)
    List<String> postfix = _convertToPostfix(tokens);

    // Evaluate the postfix expression
    return _evaluatePostfix(postfix);
  }

  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String currentNumber = '';
    bool hasDecimal = false;
    bool hasExponent = false;

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];

      if (['+', '*', '/'].contains(char) &&
          !(hasExponent && i > 0 && expression[i - 1].toLowerCase() == 'e')) {
        // Only treat as operator if not part of scientific notation
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
          hasDecimal = false;
          hasExponent = false;
        }
        tokens.add(char);
      } else if (char == '-') {
        // Check if minus is a negative sign or subtraction operator
        if (i == 0 || ['+', '-', '*', '/'].contains(expression[i - 1])) {
          // It's a negative sign
          currentNumber += char;
        } else if (hasExponent &&
            i > 0 &&
            expression[i - 1].toLowerCase() == 'e') {
          // It's a negative exponent (e.g., 1.2e-10)
          currentNumber += char;
        } else {
          // It's a subtraction operator
          if (currentNumber.isNotEmpty) {
            tokens.add(currentNumber);
            currentNumber = '';
            hasDecimal = false;
            hasExponent = false;
          }
          tokens.add(char);
        }
      } else if (char == '.') {
        if (!hasDecimal) {
          currentNumber += char;
          hasDecimal = true;
        }
      } else if (char.toLowerCase() == 'e' &&
          currentNumber.isNotEmpty &&
          !hasExponent) {
        // Handle scientific notation (e.g., 1.2e+10)
        currentNumber += char;
        hasExponent = true;
      } else if (char.contains(RegExp(r'[0-9]'))) {
        currentNumber += char;
      } else if ((char == '+') &&
          hasExponent &&
          i > 0 &&
          expression[i - 1].toLowerCase() == 'e') {
        // Handle positive exponent (e.g., 1.2e+10)
        currentNumber += char;
      }
    }

    // Add the last number
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    return tokens;
  }

  List<String> _convertToPostfix(List<String> tokens) {
    List<String> output = [];
    List<String> operatorStack = [];

    Map<String, int> precedence = {'+': 1, '-': 1, '*': 2, '/': 2};

    for (String token in tokens) {
      if (['+', '-', '*', '/'].contains(token)) {
        // Operator
        while (operatorStack.isNotEmpty &&
            precedence[operatorStack.last] != null &&
            precedence[operatorStack.last]! >= precedence[token]!) {
          output.add(operatorStack.removeLast());
        }
        operatorStack.add(token);
      } else {
        // Number
        output.add(token);
      }
    }

    // Add remaining operators to output
    while (operatorStack.isNotEmpty) {
      output.add(operatorStack.removeLast());
    }

    return output;
  }

  double _evaluatePostfix(List<String> postfix) {
    List<double> stack = [];

    for (String token in postfix) {
      if (['+', '-', '*', '/'].contains(token)) {
        // Operator
        if (stack.length < 2) {
          throw Exception("Invalid expression");
        }

        double b = stack.removeLast();
        double a = stack.removeLast();

        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) {
              throw Exception("Division by zero");
            }
            stack.add(a / b);
            break;
        }
      } else {
        // Number
        stack.add(double.parse(token));
      }
    }

    if (stack.length != 1) {
      throw Exception("Invalid expression");
    }

    return stack[0];
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
