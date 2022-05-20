import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  initState() {
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

  void _extractMapInfo() {
    final position = mapController!.cameraPosition;
    if (position != null) _position = position;
    _isMoving = mapController!.isCameraMoving;
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
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
