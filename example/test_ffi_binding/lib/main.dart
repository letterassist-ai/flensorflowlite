import 'package:flutter/material.dart';

import 'package:flensorflowlite/flensorflowlite.dart' as flensorflowlite;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  flensorflowlite.initTensorFlowLightBindings().then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String version;

  @override
  void initState() {
    super.initState();
    version = flensorflowlite.version;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const spacerLarge = SizedBox(height: 20);
    const spacerSmall = SizedBox(height: 10);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flusseract OCR Plugin Test App'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  spacerLarge,
                  const Divider(),
                  spacerSmall,
                  Text(
                    'TensorFlow Lite Version = $version',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  spacerSmall,
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
