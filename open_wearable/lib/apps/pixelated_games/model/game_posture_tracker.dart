import "package:flutter/material.dart";
import "package:open_wearable/apps/posture_tracker/model/attitude.dart";
import "package:open_wearable/apps/posture_tracker/model/attitude_tracker.dart";

class GamePostureTracker with ChangeNotifier {
  static const double rollThreshold = 0.4;
  static const double pitchThreshold = 0.16;

  GameControl _currentControl = GameControl.neutral;
  GameControl get currentControl => _currentControl;

  Attitude _attitude = Attitude();
  Attitude get attitude => _attitude;
  
  bool get isTracking => _attitudeTracker.isTracking;
  bool get isAvailable => _attitudeTracker.isAvailable;

  final AttitudeTracker _attitudeTracker;
  bool _isDisposed = false;

  GamePostureTracker(this._attitudeTracker) {
    _attitudeTracker.listen((attitude) {
      _currentControl = getGameControlFromAttitude(attitude);
      _attitude = Attitude(
          roll: attitude.roll, pitch: attitude.pitch, yaw: attitude.yaw,);
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  void startTracking() {
    _attitudeTracker.start();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void stopTracking() {
    _attitudeTracker.stop();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void calibrate() {
    _attitudeTracker.calibrateToCurrentAttitude();
  }

  @override
  void dispose() {
    stopTracking();
    _attitudeTracker.cancel();
    _isDisposed = true;
    super.dispose();
  }
}

enum GameControl {
  neutral,
  left,
  right,
  up,
  down
}

GameControl getGameControlFromAttitude(Attitude attitude) {
   if (attitude.roll > GamePostureTracker.rollThreshold) {
    return GameControl.right;
  } else if (attitude.roll < -GamePostureTracker.rollThreshold) {
    return GameControl.left;
  } else if(attitude.pitch > GamePostureTracker.pitchThreshold) {
    return GameControl.down;
  } else if (attitude.pitch < -GamePostureTracker.pitchThreshold) {
    return GameControl.up;
  } else {
    return GameControl.neutral;
  }
}
