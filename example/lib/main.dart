/// Copyright (C) 2018-2022 Jason C.H
///
/// This library is free software; you can redistribute it and/or
/// modify it under the terms of the GNU Lesser General Public
/// License as published by the Free Software Foundation; either
/// version 2.1 of the License, or (at your option) any later version.
///
/// This library is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
/// Lesser General Public License for more details.
import 'package:flutter/material.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:flutter_vpn/state.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _proxyController = TextEditingController(text: "socks5://192.168.0.105:7890");

  var state = FlutterVpnState.disconnected;

  @override
  void initState() {
    FlutterVpn.prepare();
    FlutterVpn.onStateChanged.listen((s) => setState(() => state = s));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter VPN'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            Text('Current State: $state'),
            TextFormField(
              controller: _proxyController,
              decoration: const InputDecoration(icon: Icon(Icons.map_outlined)),
            ),
            ElevatedButton(
              child: const Text('Connect'),
              onPressed: () => FlutterVpn.connect(
                proxy: _proxyController.text,
              ),
            ),
            ElevatedButton(
              child: const Text('Disconnect'),
              onPressed: () => FlutterVpn.disconnect(),
            ),
            ElevatedButton(
              child: const Text('ChangeProxy'),
              onPressed: () => FlutterVpn.changeProxy(
                proxy: _proxyController.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
