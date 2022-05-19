import 'package:flutter/material.dart';
import 'package:geolocator_demo/view/home_page.dart';
import 'package:geolocator_demo/viewmodel/location_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => LocationViewModel())],
    child: Builder(builder: (context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      );
    }),
  ));
}
