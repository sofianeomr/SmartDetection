import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_detection_app/MqttHandler.dart';
import 'package:smart_detection_app/firebase_options.dart';
import 'package:smart_detection_app/push_notification.dart';
import 'collision_details_page.dart';
import 'dart:async';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  PushNotifications.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MqttHandler(),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: const MyStatefulWidget(),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> with SingleTickerProviderStateMixin {
  late MqttHandler mqttHandler;
  bool isProximityTriggered = false;
  double _leftPosition = 50;
  bool _imageExists = true;
  bool isRedLightVisible = true;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    mqttHandler = Provider.of<MqttHandler>(context, listen: false);
    mqttHandler.connect();
    mqttHandler.frontSensor.addListener(() => setState(() {}));
    mqttHandler.backSensor.addListener(() => setState(() {}));
    mqttHandler.leftSensor.addListener(() => setState(() {}));
    mqttHandler.rightSensor.addListener(() => setState(() {}));
    mqttHandler.proximitySensor.addListener(() {
      setState(() {
        isProximityTriggered = mqttHandler.proximitySensor.value;
        if (isProximityTriggered) {
          _startProximityAnimation();
        }
      });
    });

    mqttHandler.frontSensor.addListener(() => _handleSensorChange(mqttHandler.frontSensor.value));
    mqttHandler.backSensor.addListener(() => _handleSensorChange(mqttHandler.backSensor.value));
    mqttHandler.leftSensor.addListener(() => _handleSensorChange(mqttHandler.leftSensor.value));
    mqttHandler.rightSensor.addListener(() => _handleSensorChange(mqttHandler.rightSensor.value));

    _checkImageExists();
  }

  void _handleSensorChange(bool isTriggered) {
    if (isTriggered) {
      _startRedLightBlinking();
    } else {
      _stopRedLightBlinking();
    }
  }

  void _startProximityAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && isProximityTriggered) {
        setState(() {
          _leftPosition = _leftPosition == 80 ? 150 : 50;
        });
        _startProximityAnimation();
      }
    });
  }

  void _startRedLightBlinking() {
    _blinkTimer?.cancel();  // Cancel any existing timer
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        isRedLightVisible = !isRedLightVisible;
      });
    });
  }

  void _stopRedLightBlinking() {
    _blinkTimer?.cancel();
    setState(() {
      isRedLightVisible = true;
    });
  }

  Future<void> _checkImageExists() async {
    try {
      // Replace 'assets/empreinte2.gif' with the actual path to your image
      await rootBundle.load('assets/empreinte2.gif');
      setState(() {
        _imageExists = true;
      });
    } catch (e) {
      setState(() {
        _imageExists = false;
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  Widget _buildSensorIndicator(bool isTriggered, Offset offset, double width, double height, String sensorName) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: () {
          if (isTriggered) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollisionDetailsPage(sensorName: sensorName),
              ),
            );
          }
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(75),
            color: isTriggered && isRedLightVisible ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildProximityIndicator(bool isTriggered) {
    if (!isTriggered) return Container();

    return AnimatedPositioned(
      left: -20,
      top: -5,
      duration: const Duration(milliseconds: 300),
      child: _imageExists
          ? Image.asset(
              'assets/empreinte2.gif',
              width: 100,
              height: 100,
            )
          : Container(
              width: 100,
              height: 100,
              color: Colors.grey,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('Smart Detection App'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 500,
              child: Image.asset('assets/voiture.png'),
            ),
            _buildSensorIndicator(mqttHandler.frontSensor.value, const Offset(50, 0), 150, 80, 'Front Sensor'),
            _buildSensorIndicator(mqttHandler.backSensor.value, const Offset(50, 420), 150, 80, 'Back Sensor'),
            _buildSensorIndicator(mqttHandler.leftSensor.value, const Offset(0, 150), 80, 200, 'Left Sensor'),
            _buildSensorIndicator(mqttHandler.rightSensor.value, const Offset(170, 150), 80, 200, 'Right Sensor'),
            if (mqttHandler.proximitySensor.value) _buildProximityIndicator(mqttHandler.proximitySensor.value),
          ],
        ),
      ),
    );
  }
}
