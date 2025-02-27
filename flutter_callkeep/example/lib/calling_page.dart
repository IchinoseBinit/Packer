import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_callkeep_example/navigation_service.dart';
import 'package:http/http.dart';

class CallingPage extends StatefulWidget {
  const CallingPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CallingPageState();
  }
}

class CallingPageState extends State<CallingPage> {
  late CallEvent? calling;

  @override
  Widget build(BuildContext context) {
    final params = jsonDecode(jsonEncode(
        ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>));
    calling = CallEvent.fromMap(params);
    debugPrint(calling?.toString());

    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Calling...'),
              TextButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () async {
                  if (calling != null) {
                    CallKeep.instance.endCall(calling!.uuid);
                    calling = null;
                  }
                  NavigationService.instance.goBack();
                  await requestHttp('END_CALL');
                },
                child: const Text('End Call'),
              )
            ],
          ),
        ),
      ),
    );
  }

  //check with https://webhook.site/#!/2748bc41-8599-4093-b8ad-93fd328f1cd2
  Future<void> requestHttp(content) async {
    get(Uri.parse(
        'https://webhook.site/2748bc41-8599-4093-b8ad-93fd328f1cd2?data=$content'));
  }

  @override
  void dispose() {
    super.dispose();
    if (calling != null) CallKeep.instance.endCall(calling!.uuid);
  }
}
