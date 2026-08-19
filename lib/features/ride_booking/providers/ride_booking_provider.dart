import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride_state.dart';
import '../models/vehicle.dart';
import '../data/mock_ride_repository.dart';

class RideBookingProvider extends ChangeNotifier {
  final MockRideRepository _repository;
  static const String _apiKey = 'AIzaSyBcVNOX83jHMMtpeH5Dk9rfUT6d6vGvVM0';
  
  RideBookingProvider(this._repository);

  String pickupLocation = '';
  LatLng? pickupCoords;

  String dropLocation = '';
  LatLng? dropCoords;
  
  Vehicle? selectedVehicle;
  
  RideState _currentState = RideState.initial;
  RideState get currentState => _currentState;
  
  StreamSubscription<RideState>? _rideStatusSubscription;
  GoogleMapController? mapController;
  
  Set<Polyline> _polylines = {};

  List<Vehicle> availableVehicles = [
    const Vehicle(id: '1', name: 'Bike', estimatedFare: 50.0),
    const Vehicle(id: '2', name: 'Auto', estimatedFare: 80.0),
    const Vehicle(id: '3', name: 'Cab', estimatedFare: 150.0),
    const Vehicle(id: '4', name: 'XL Cab', estimatedFare: 220.0),
  ];

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void setPickup(String location, [LatLng? coords]) {
    pickupLocation = location;
    if (coords != null) {
      pickupCoords = coords;
      _animateCameraTo(coords);
      _checkAndFetchRoute();
    }
    notifyListeners();
  }

  void setDrop(String location, [LatLng? coords]) {
    dropLocation = location;
    if (coords != null) {
      dropCoords = coords;
      _fitMapToMarkers();
      _checkAndFetchRoute();
    }
    notifyListeners();
  }
  
  Future<void> _checkAndFetchRoute() async {
    if (pickupCoords != null && dropCoords != null) {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=\${pickupCoords!.latitude},\${pickupCoords!.longitude}&destination=\${dropCoords!.latitude},\${dropCoords!.longitude}&key=$_apiKey');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0];
            final leg = route['legs'][0];
            
            // Extract Distance (meters) and Duration (seconds)
            final distanceMeters = leg['distance']['value'] as int;
            final durationSeconds = leg['duration']['value'] as int;
            
            _calculateDynamicFares(distanceMeters / 1000, durationSeconds / 60);

            // Draw Polyline
            final points = _decodePoly(route['overview_polyline']['points']);
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blueAccent,
                width: 5,
                points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
              )
            };
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Route fetch error: \$e');
      }
    }
  }

  void _calculateDynamicFares(double distanceKm, double durationMins) {
    availableVehicles = [
      Vehicle(id: '1', name: 'Bike', estimatedFare: (10 + (distanceKm * 5) + (durationMins * 1)).roundToDouble()),
      Vehicle(id: '2', name: 'Auto', estimatedFare: (20 + (distanceKm * 8) + (durationMins * 1.5)).roundToDouble()),
      Vehicle(id: '3', name: 'Cab', estimatedFare: (40 + (distanceKm * 12) + (durationMins * 2)).roundToDouble()),
      Vehicle(id: '4', name: 'XL Cab', estimatedFare: (60 + (distanceKm * 18) + (durationMins * 3)).roundToDouble()),
    ];
    // Automatically reselect vehicle with new price if one was already selected
    if (selectedVehicle != null) {
      selectedVehicle = availableVehicles.firstWhere((v) => v.id == selectedVehicle!.id);
    }
    notifyListeners();
  }

  void selectVehicle(Vehicle vehicle) {
    selectedVehicle = vehicle;
    notifyListeners();
  }

  Future<void> bookRide() async {
    if (pickupLocation.isEmpty || dropLocation.isEmpty || selectedVehicle == null) {
      return;
    }
    
    _currentState = RideState.searchingForDriver;
    notifyListeners();
    
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = _repository.bookRide().listen((state) {
      _currentState = state;
      notifyListeners();
    });
  }
  
  void resetRide() {
    _rideStatusSubscription?.cancel();
    _currentState = RideState.initial;
    pickupLocation = '';
    pickupCoords = null;
    dropLocation = '';
    dropCoords = null;
    selectedVehicle = null;
    _polylines.clear();
    // Reset to base fares
    _calculateDynamicFares(0, 0);
    notifyListeners();
  }

  void _animateCameraTo(LatLng target) {
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  void _fitMapToMarkers() {
    if (pickupCoords != null && dropCoords != null && mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          pickupCoords!.latitude < dropCoords!.latitude ? pickupCoords!.latitude : dropCoords!.latitude,
          pickupCoords!.longitude < dropCoords!.longitude ? pickupCoords!.longitude : dropCoords!.longitude,
        ),
        northeast: LatLng(
          pickupCoords!.latitude > dropCoords!.latitude ? pickupCoords!.latitude : dropCoords!.latitude,
          pickupCoords!.longitude > dropCoords!.longitude ? pickupCoords!.longitude : dropCoords!.longitude,
        ),
      );
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Set<Marker> getMarkers() {
    final markers = <Marker>{};
    if (pickupCoords != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupCoords!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (dropCoords != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: dropCoords!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    
    // Simplified Car Marker
    if (_currentState == RideState.driverAssigned || _currentState == RideState.driverArriving) {
      if (pickupCoords != null) {
        markers.add(Marker(
          markerId: const MarkerId('car'),
          position: LatLng(pickupCoords!.latitude - 0.002, pickupCoords!.longitude - 0.002), // offset slightly
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }
    } else if (_currentState == RideState.rideStarted) {
      if (pickupCoords != null && dropCoords != null) {
        // halfway point simulation
        markers.add(Marker(
          markerId: const MarkerId('car'),
          position: LatLng(
            (pickupCoords!.latitude + dropCoords!.latitude) / 2,
            (pickupCoords!.longitude + dropCoords!.longitude) / 2,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }
    }

    return markers;
  }
  
  Set<Polyline> getPolylines() => _polylines;

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    super.dispose();
  }
}
