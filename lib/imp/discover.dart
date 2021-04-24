import 'dart:convert';
import 'dart:io';
import 'dart:async';

import '../protocol.dart';
import 'device.dart';
import 'packet.dart';

class DiscoverServiceImp implements DiscoverService {
  @override
  Future<Device> connect(String url) {
    return DeviceImp.from(url);
  }

  @override
  Stream<Device> discover(InternetAddress address, {int hops = 1}) {
    Future<RawDatagramSocket> socketFuture = RawDatagramSocket.bind(address, 0, ttl: hops);
    StreamController<Device> controller;
    Set<String> repeated = Set();
    Timer timer;
    bool run = false;

    socketFuture.then(
      (socket) => socket.listen((event) async {
        if (socket == null || !run) return;
        Datagram datagram = socket.receive();
        if (datagram != null) {
          final lines = utf8.decode(datagram.data).split('\n');
          final locationLine = lines.firstWhere((line) => line.toLowerCase().contains("location"));
          final url = locationLine.trim().substring(10);
          if (!repeated.contains(url)) {
            repeated.add(url);
            controller.add(await DeviceImp.from(url));
          }
        }
      }),
    );

    void start() async {
      run = true;
      RawDatagramSocket socket = await socketFuture;
      socket.multicastHops = hops;
      if (run) {
        timer = Timer.periodic(
          Duration(seconds: 5),
          (timer) {
            try {
              socket.send(packet, broadcast, 1900);
            } catch (error) {
              print(error);
            }
          },
        );
      }
    }

    void pause() {
      run = false;
      if (timer != null) {
        timer.cancel();
      }
    }

    void cancel() async {
      run = false;
      if (timer != null) {
        timer.cancel();
      }
      (await socketFuture).close();
      controller.close();
    }

    controller = StreamController<Device>(
      onListen: start,
      onResume: start,
      onPause: pause,
      onCancel: cancel,
    );

    return controller.stream;
  }
}
