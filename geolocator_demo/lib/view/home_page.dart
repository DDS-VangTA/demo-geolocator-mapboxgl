import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_demo/view/steps_counter_demo.dart';
import 'package:geolocator_demo/viewmodel/location_view_model.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  String accessToken =
      "sk.eyJ1IjoidmFuZ3RoYW9hIiwiYSI6ImNsM2Nzbmo5ajAxNjAzcHMwaXgxNXp3eWsifQ.y3UfGn9GIZSgd5CMEQb15w";
  final String style = 'url-to-style';
  late LocationViewModel locationViewModel;
  late bool serviceEnabled;
  late LocationPermission permission;
  late StreamSubscription<Position> positionStream;
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
  );

  MapboxMapController? mapController;

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(-33.852, 151.211),
    zoom: 15.0,
  );

  CameraPosition _position = initialCameraPosition;
  bool _isMoving = false;
  bool _telemetryEnabled = true;

  List<LatLng> latlngList = <LatLng>[];

  @override
  initState() {
    loadAsset();
    super.initState();
  }

  void startRecord() {
    locationViewModel.initPlatformState();
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        locationViewModel.onAddPositionToList(position);
        locationViewModel.calculateDistanceMoved();
        locationViewModel.calculateVelocity();
        locationViewModel.getLastKnownLocation();
        //move camera on map to new location
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 15.0)));
        onDrawNewLinesOnMap();
      } else {
        Fluttertoast.showToast(
            msg: "Position is NULL",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.grey,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
  }

  void pauseRecord() {
    positionStream.pause();
  }

  void resumeRecord() {
    positionStream.resume();
  }

  void stopRecord() {
    locationViewModel.onResetData();
    positionStream.cancel();
  }

  void onMapCreated(MapboxMapController controller) {
    mapController = controller;

    // List<LatLng> points = [];
    //draw polyline with position moved
    // for (var position in locationViewModel.locationList) {
    //   points.add(LatLng(position.latitude, position.longitude));

    //fake data to draw
    // points.add(LatLng(20.984002597614563, 105.79126096843653)); //So 10 Tran phu
    // points.add(LatLng(20.983009606350265, 105.79080279506958)); //Circle-K
    // points.add(LatLng(20.98205795306445, 105.78946705504819)); //Hoang ha mobile
    // points.add(LatLng(20.98182254313985, 105.78925784268469)); //Laforce
    // points.add(LatLng(20.98029487411198, 105.78746076270735)); //ATM Teckcombank
    // points.add(
    //     LatLng(20.978085987334936, 105.78476782486356)); //Xuong cafe Ha dong
    // points.add(LatLng(20.977499950656256, 105.78397925540837)); //Ellipse Tower
    // points.add(LatLng(20.975140754184093, 105.78103955438436)); //NCBBank
    // points.add(LatLng(20.974204077715363, 105.78153844520841)); //ATM-BIDV
    // points.add(
    //     LatLng(20.97334016845801, 105.7828781293542)); //Hanoi Culture Center
    // points.add(
    //     LatLng(20.973987105620083, 105.78641217897905)); //San bong Van quan
    // mapController?.addLine(
    //   LineOptions(
    //       geometry: points,
    //       lineColor: "#ff0000",
    //       lineWidth: 5.0,
    //       lineOpacity: 0.8,
    //       draggable: true),
    // );
    mapController!.addListener(_onMapChanged);
    _extractMapInfo();

    mapController!.getTelemetryEnabled().then((isEnabled) => setState(() {
          _telemetryEnabled = isEnabled;
        }));
  }

  void _onMapChanged() {
    setState(() {
      _extractMapInfo();
    });
  }

  void onDrawNewLinesOnMap() {
    print("on draw new lines");
    setState(() {
      List<LatLng> points = [];
      for (var position in locationViewModel.locationList) {
        points.add(LatLng(position.latitude, position.longitude));
      }
      mapController?.addLine(
        LineOptions(
            geometry: points,
            lineColor: "#ff0000",
            lineWidth: 5.0,
            lineOpacity: 0.8,
            draggable: true),
      );
    });
  }

  void _extractMapInfo() {
    final position = mapController!.cameraPosition;
    if (position != null) _position = position;
    _isMoving = mapController!.isCameraMoving;
  }

  List<LatLng> _getListOfLatLong() {
    List<LatLng> list = [];
    list.add(LatLng(-7.919335, 31.135638));
    list.add(LatLng(-7.919404, 31.125363));
    list.add(LatLng(-7.919638, 31.113153));
    list.add(LatLng(-7.847774, 31.017294));
    list.add(LatLng(-7.833659, 31.015464));
    list.add(LatLng(-7.836902, 31.017383));
    list.add(LatLng(-7.836709, 31.023768));
    list.add(LatLng(-7.844098, 31.04391));
    list.add(LatLng(-7.847022, 31.047187));
    list.add(LatLng(-7.851609, 31.060459));
    return list;
  }

  void loadAsset() {
    _getListOfLatLong().forEach((element) {
      latlngList.add(LatLng(element.latitude, element.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    locationViewModel = Provider.of<LocationViewModel>(context, listen: true);
    // checkLocationEnable();
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  locationViewModel.locationList.isNotEmpty
                      ? Container(
                          width: MediaQuery.of(context).size.width,
                          height: 300,
                          child: MapboxMap(
                            accessToken: accessToken,
                            onMapCreated: onMapCreated,
                            // styleString: style,
                            myLocationEnabled: true,
                            initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    locationViewModel
                                        .locationList.last.latitude,
                                    locationViewModel
                                        .locationList.last.longitude),
                                zoom: 15.0),
                            myLocationRenderMode: MyLocationRenderMode.COMPASS,
                            trackCameraPosition: true,
                            attributionButtonPosition:
                                AttributionButtonPosition.BottomLeft,
                            annotationOrder: [
                              AnnotationType.line,
                              AnnotationType.circle
                            ],
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width,
                          height: 300,
                          child: MapboxMap(
                            accessToken: accessToken,
                            onMapCreated: onMapCreated,
                            // styleString: style,
                            initialCameraPosition: initialCameraPosition,
                            myLocationEnabled: true,
                            myLocationRenderMode: MyLocationRenderMode.COMPASS,
                            trackCameraPosition: true,
                            attributionButtonPosition:
                                AttributionButtonPosition.BottomLeft,
                            annotationOrder: [
                              AnnotationType.line,
                              AnnotationType.circle
                            ],
                          ),
                        ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(padding: EdgeInsets.only(top: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Center(
                              child: Text(
                            "${locationViewModel.velocity}",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ))),
                      Expanded(
                          flex: 3,
                          child: Center(
                              child: Text("${locationViewModel.distanceMoved}",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20)))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Center(child: Text("Velocity(km/h)"))),
                      Expanded(
                          flex: 3, child: Center(child: Text("Distance(m)")))
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(top: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Center(
                              child: Text(
                            "${locationViewModel.steps}",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ))),
                      Expanded(
                          flex: 3,
                          child: Center(
                              child: Text("${locationViewModel.status}",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20)))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(flex: 3, child: Center(child: Text("Steps"))),
                      Expanded(flex: 3, child: Center(child: Text("Status")))
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(top: 16)),
                  locationViewModel.locationList.isNotEmpty
                      ? Text(
                          "Current position: lat:${locationViewModel.locationList.last.latitude}, lon:${locationViewModel.locationList.last.longitude}")
                      : Text("Current position: Unknown"),
                  locationViewModel.lastKnownLocation != null
                      ? Text(
                          "Last known location: lat:${locationViewModel.lastKnownLocation?.latitude}, lon:${locationViewModel.lastKnownLocation?.longitude}")
                      : Text("Last knonw location: Unknown"),
                  locationViewModel.locationList.isNotEmpty
                      ? Text(
                          "List location length:${locationViewModel.locationList.length}")
                      : Text("List location length:0"),
                  Padding(padding: EdgeInsets.only(top: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: ElevatedButton(
                            onPressed: () {
                              startRecord();
                            },
                            child: Text('Start record')),
                      ),
                      Padding(padding: EdgeInsets.only(left: 8)),
                      Center(
                        child: ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(primary: Colors.grey),
                            onPressed: () {
                              print("click pause");
                              pauseRecord();
                            },
                            child: Text('Pause')),
                      ),
                      Padding(padding: EdgeInsets.only(left: 8)),
                      Center(
                        child: ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(primary: Colors.green),
                            onPressed: () {
                              print("click resume");
                              resumeRecord();
                            },
                            child: Text('Resume')),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(primary: Colors.red),
                            onPressed: () {
                              print("click stop");
                              stopRecord();
                            },
                            child: Text('Stop')),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
