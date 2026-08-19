import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_booking_provider.dart';
import '../../models/ride_state.dart';
import '../widgets/location_input.dart';
import '../widgets/vehicle_selector.dart';
import '../widgets/ride_status_card.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/map_style.dart';

class RideBookingScreen extends StatelessWidget {
  const RideBookingScreen({super.key});

  Future<void> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (!context.mounted) return;
    
    final provider = context.read<RideBookingProvider>();
    if (provider.pickupCoords == null) {
      provider.mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideBookingProvider>();
    final state = provider.currentState;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: minimalMapStyle,
            markers: provider.getMarkers(),
            polylines: provider.getPolylines(),
            onMapCreated: (GoogleMapController controller) {
              provider.setMapController(controller);
              _determinePosition(context);
            },
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state == RideState.initial
                    ? const _InitialBookingView()
                    : const RideStatusCard(),
              ),
            ),
          ),
          if (state == RideState.initial)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialBookingView extends StatelessWidget {
  const _InitialBookingView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideBookingProvider>();
    final canBook = provider.pickupLocation.isNotEmpty && 
                    provider.dropLocation.isNotEmpty && 
                    provider.selectedVehicle != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  LocationInput(),
                  SizedBox(height: 24),
                  VehicleSelector(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canBook ? () => context.read<RideBookingProvider>().bookRide() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Book Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
