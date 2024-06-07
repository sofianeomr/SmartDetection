import 'package:flutter/material.dart';
import 'package:smart_detection_app/MqttHandler.dart';

class CollisionDetailsPage extends StatelessWidget {
  final String sensorName;

  const CollisionDetailsPage({Key? key, required this.sensorName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imagePath;
    switch (sensorName) {
      case 'Front Sensor':
        imagePath = 'assets/front_collision.png';
        break;
      case 'Back Sensor':
        imagePath = 'assets/back_collision.png';
        break;
      case 'Left Sensor':
        imagePath = 'assets/left_collision.png';
        break;
      case 'Right Sensor':
        imagePath = 'assets/right_collision.png';
        break;
      default:
        imagePath = 'assets/voiture.png';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collision Details'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFF1E1E1E), // Background color
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Collision Detected on $sensorName',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(imagePath),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Publish message to turn on camera
                  MqttHandler().pubMessage("on", "topic/camera");
                  // Logic for starting video recording goes here
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.redAccent,
                  onPrimary: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Commencer l\'enregistrement vidéo'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
