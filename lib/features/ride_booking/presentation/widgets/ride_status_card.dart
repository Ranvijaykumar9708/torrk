import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_booking_provider.dart';
import '../../models/ride_state.dart';
import '../../../../core/services/payment_service.dart';

class RideStatusCard extends StatefulWidget {
  const RideStatusCard({super.key});

  @override
  State<RideStatusCard> createState() => _RideStatusCardState();
}

class _RideStatusCardState extends State<RideStatusCard> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(context, () {
      context.read<RideBookingProvider>().resetRide();
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RideBookingProvider>().currentState;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatusIndicator(state),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusText(state)),
                ],
              ),
              const SizedBox(height: 24),
              if (state == RideState.rideCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = context.read<RideBookingProvider>().selectedVehicle?.estimatedFare ?? 150.0;
                      _paymentService.openCheckout(amount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Pay with Razorpay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFEEEEEE),
                    color: Colors.black,
                    minHeight: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(RideState state) {
    IconData icon;
    Color color = Colors.black87;
    
    switch (state) {
      case RideState.searchingForDriver:
        icon = Icons.search;
        break;
      case RideState.driverAssigned:
        icon = Icons.person;
        break;
      case RideState.driverArriving:
        icon = Icons.directions_car;
        break;
      case RideState.rideStarted:
        icon = Icons.play_arrow;
        break;
      case RideState.rideCompleted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusText(RideState state) {
    String title;
    String subtitle;
    
    switch (state) {
      case RideState.searchingForDriver:
        title = 'Searching...';
        subtitle = 'Finding the nearest driver';
        break;
      case RideState.driverAssigned:
        title = 'Driver Assigned';
        subtitle = 'Suresh is on the way';
        break;
      case RideState.driverArriving:
        title = 'Arriving Shortly';
        subtitle = 'Your driver is nearby';
        break;
      case RideState.rideStarted:
        title = 'Ride Started';
        subtitle = 'Enjoy your journey';
        break;
      case RideState.rideCompleted:
        title = 'Completed';
        subtitle = 'You have reached your destination';
        break;
      default:
        title = 'Status';
        subtitle = 'Waiting...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }
}
