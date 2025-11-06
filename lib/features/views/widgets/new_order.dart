import 'dart:async';

import 'package:flutter/material.dart';

class NewOrderWidget extends StatefulWidget {
  const NewOrderWidget({Key? key}) : super(key: key);
  @override
  _NewOrderWidgetState createState() => _NewOrderWidgetState();
}

class _NewOrderWidgetState extends State<NewOrderWidget> {
  int _countdownSeconds = 20 * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds == 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New Order!'),
            SizedBox(height: 16),
            Text(
                'Will be packed on ${Duration(seconds: _countdownSeconds).inMinutes.toString().padLeft(2, '0')}:${(Duration(seconds: _countdownSeconds).inSeconds % 60).toString().padLeft(2, '0')}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the next screen
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
