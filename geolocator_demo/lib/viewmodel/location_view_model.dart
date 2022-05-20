import 'dart:async';

import 'package:geolocator_demo/base/base_view_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_demo/utilitis/number_const.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationViewModel extends BaseViewModel {
  static final LocationViewModel _instance = LocationViewModel._internal();

  factory LocationViewModel() {
    return _instance;
  }

  LocationViewModel._internal();

  List<Position> locationList = [];

  late bool serviceEnabled;
  late LocationPermission permission;
  Position? currentLocation;
  Position? lastKnownLocation;
  double velocity = 0.0;
  double distanceMoved = 0.0;
  double stepsCount = 0;
  late Stream<StepCount> stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String status = '?', steps = '?';
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
  );

  @override
  FutureOr<void> init() {
    checkLocationEnable();
    if (currentLocation != null) {
      print("current location init:$currentLocation");
      locationList.add(currentLocation!);
    }
  }

  Future<void> checkLocationEnable() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location service are disabled");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission are denied.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    currentLocation = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  Future<void> getLastKnownLocation() async {
    lastKnownLocation = await Geolocator.getLastKnownPosition();
    notifyListeners();
  }

  onAddPositionToList(Position position) {
    print("add new position:$position");
    locationList.add(position);
    notifyListeners();
  }

  onResetData() {
    locationList = [];
    velocity = 0.0;
    distanceMoved = 0.0;
    stepsCount = 0;
    steps = 0.toString();
    status = '?';
    notifyListeners();
  }

  calculateDistanceMoved() async {
    if (locationList.length >= 2) {
      distanceMoved += Geolocator.distanceBetween(
          locationList[locationList.length - 2].latitude,
          locationList[locationList.length - 2].longitude,
          locationList.last.latitude,
          locationList.last.longitude);
      notifyListeners();
    }
  }

  calculateVelocity() {
    // V  = s/t
    //V : Vận tốc (km/h)
    if (locationList.length >= 2) {
      double distance = Geolocator.distanceBetween(
          locationList[locationList.length - 2].latitude,
          locationList[locationList.length - 2].longitude,
          locationList.last.latitude,
          locationList.last.longitude);
      velocity = distance / NumberConst.updatePositionTime;
      //Doi tu m/s => Km/h;
      velocity = velocity * 3.6;
      print("velocity:$velocity");
      notifyListeners();
    }
  }

  onDistanceMovedChanged(double distance) {
    distanceMoved = distance;
    notifyListeners();
  }

  void onStepCount(StepCount event) {
    print("step count event:$event");
    steps = event.steps.toString();
    notifyListeners();
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print("PedestrianStatus event:$event");
    status = event.status;
    notifyListeners();
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    status = 'Pedestrian Status not available';
    print("PedestrianStatus status :$status");
    notifyListeners();
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    steps = 'Step Count not available';
    notifyListeners();
  }

  Future<void> initPlatformState() async {
    print("call do steps count");
    steps = 0.toString();
    status = '?';
    if (await Permission.activityRecognition.request().isGranted) {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusStream
          .listen(onPedestrianStatusChanged)
          .onError(onPedestrianStatusError);

      stepCountStream = Pedometer.stepCountStream;
      stepCountStream.listen(onStepCount).onError(onStepCountError);
      notifyListeners();
    } else {
      print("request activity recognition");
      await Permission.activityRecognition.request();
    }
  }
}
