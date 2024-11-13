import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:twenty_forty_eight/models/board_adapter.dart';
import 'package:twenty_forty_eight/screens/game_screen.dart';

void main() async {
  //Only portrait mode on Android & iOS
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp]
  );

  //Make sure Hive is initialized first and only after register the adapter
  await Hive.initFlutter();
  Hive.registerAdapter(BoardAdapter());
  
  runApp(const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2048',
      home: Game(),
    )
  ));
}


