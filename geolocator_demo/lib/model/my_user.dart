import 'package:geolocator/geolocator.dart';

class MyUser {
  List<Position> positionList = [];
  Position? currentPosition;
  Position? lastKnownPosition;
  double velocity = 0.0;
  double distanceMoved = 0.0;
  int stepsCount = 0;

  MyUser(
      {required this.positionList,
      required this.currentPosition,
      required this.lastKnownPosition,
      required this.velocity,
      required this.distanceMoved,
      required this.stepsCount});
}
