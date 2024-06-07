import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_detection_app/push_notification.dart';

class MqttHandler with ChangeNotifier {
  final ValueNotifier<bool> frontSensor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> backSensor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> leftSensor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> rightSensor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> proximitySensor = ValueNotifier<bool>(false);
  final ValueNotifier<bool> camera = ValueNotifier<bool>(false);
  late MqttServerClient client;

  MqttHandler() {
    _initializeClient();
  }

  void _initializeClient() {
    client = MqttServerClient.withPort('test.mosquitto.org', 'flutter_client', 1883)
      ..logging(on: true)
      ..onConnected = onConnected
      ..onDisconnected = onDisconnected
      ..onUnsubscribed = onUnsubscribed
      ..onSubscribed = onSubscribed
      ..onSubscribeFail = onSubscribeFail
      ..pongCallback = pong
      ..keepAlivePeriod = 60
      ..setProtocolV311();
  }

  Future<void> connect() async {
    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    print('MQTT_LOGS::Mosquitto client connecting....');

    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT_LOGS::Mosquitto client connected');
    } else {
      print('MQTT_LOGS::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      return;
    }

    // Subscribe to multiple topics
    const topics = [
      'topic/frontSensor',
      'topic/backSensor',
      'topic/leftSensor',
      'topic/rightSensor',
      'topic/proximitySensor',
      'topic/camera' // New topic for camera
    ];
    for (var topic in topics) {
      print('MQTT_LOGS::Subscribing to the $topic topic');
      client.subscribe(topic, MqttQos.atMostOnce);
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      final bool isTriggered = pt.toLowerCase() == 'true';

      switch (c[0].topic) {
        case 'topic/frontSensor':
          frontSensor.value = isTriggered;
          if (isTriggered) {
            _notifySensorTriggered('Collision avant détectée');
          }
          break;
        case 'topic/backSensor':
          backSensor.value = isTriggered;
          if (isTriggered) {
            _notifySensorTriggered('Collision arrière détectée');
          }
          break;
        case 'topic/leftSensor':
          leftSensor.value = isTriggered;
          if (isTriggered) {          
            print("here2");
            _notifySensorTriggered('Collision à droite détectée');
          }
          break;
        case 'topic/rightSensor':
          rightSensor.value = isTriggered; 
          if (isTriggered) {
            _notifySensorTriggered('Collision à gauche détectée');
          }
          break;
        case 'topic/proximitySensor':
          proximitySensor.value = isTriggered;
          if (isTriggered) {
            _notifySensorTriggered('Individu à proximité du véhicule');
          }
          break;
        case 'topic/camera':
          camera.value = isTriggered;
          print("camerahere $camera");
            if (isTriggered) {
            _notifySensorTriggered('La vidéo est enregistrée');
          }
          break;
      }
      notifyListeners();
      print('MQTT_LOGS:: New data arrived: topic is <${c[0].topic}>, payload is $pt');
    });
  }

  void _notifySensorTriggered(String sensorName) { 
    final RemoteMessage message = RemoteMessage(
      notification: RemoteNotification(
        title: 'Alert',
        body: '$sensorName',
      ),
    );

    PushNotifications.ShowNotification(message);
  }

  void onConnected() {
    print('MQTT_LOGS:: Connected');
  }

  void onDisconnected() {
    print('MQTT_LOGS:: Disconnected');
  }

  void onSubscribed(String topic) {
    print('MQTT_LOGS:: Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('MQTT_LOGS:: Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    print('MQTT_LOGS:: Unsubscribed topic: $topic');
  }

  void pong() {
    print('MQTT_LOGS:: Ping response client callback invoked');
  }

  Future<void> pubMessage(String message, String topic) async {
    print("here $message, $topic ");
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus == null || client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT_LOGS:: Client not connected, attempting to reconnect');
      await connect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      print('MQTT_LOGS:: Message published');
    } else {
      print('MQTT_LOGS:: Failed to publish message, client not connected');
    }
  }
}
