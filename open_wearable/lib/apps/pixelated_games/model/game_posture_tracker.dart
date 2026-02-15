import "package:flutter/material.dart";
import "package:open_wearable/apps/posture_tracker/model/attitude.dart";
import "package:open_wearable/apps/posture_tracker/model/attitude_tracker.dart";

/// Tracks head posture and converts it to game control inputs
/// Monitors head roll and pitch to determine directional controls
class GamePostureTracker with ChangeNotifier {
  /// Head roll threshold for triggering left/right controls (in radians)
  static const double rollThreshold = 0.4;
  /// Head pitch threshold for triggering up/down controls (in radians)
  static const double pitchThreshold = 0.16;

  /// The current game control based on head posture
  GameControl _currentControl = GameControl.neutral;
  GameControl get currentControl => _currentControl;

  /// The current head attitude measurement
  Attitude _attitude = Attitude();
  Attitude get attitude => _attitude;
  
  bool get isTracking => _attitudeTracker.isTracking;
  bool get isAvailable => _attitudeTracker.isAvailable;

  /// Underlying attitude tracker for head movement
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

  /// Starts tracking head movements
  void startTracking() {
    _attitudeTracker.start();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Stops tracking head movements
  void stopTracking() {
    _attitudeTracker.stop();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Calibrates the current head position as neutral
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

/// Enum representing the possible game control directions
enum GameControl {
  neutral,
  left,
  right,
  up,
  down
}

/// Converts head attitude measurements to game control inputs
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
