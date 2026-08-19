import 'dart:async';
import '../models/ride_state.dart';

class MockRideRepository {
  Stream<RideState> bookRide() async* {
    // Simulate initial delay
    await Future.delayed(const Duration(seconds: 1));
    yield RideState.searchingForDriver;
    
    await Future.delayed(const Duration(seconds: 3));
    yield RideState.driverAssigned;
    
    await Future.delayed(const Duration(seconds: 2));
    yield RideState.driverArriving;
    
    await Future.delayed(const Duration(seconds: 3));
    yield RideState.rideStarted;
    
    await Future.delayed(const Duration(seconds: 5));
    yield RideState.rideCompleted;
  }
}
