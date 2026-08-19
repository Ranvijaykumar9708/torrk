import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_booking_provider.dart';

class VehicleSelector extends StatelessWidget {
  const VehicleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideBookingProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Vehicle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: provider.availableVehicles.map((vehicle) {
              final isSelected = provider.selectedVehicle?.id == vehicle.id;
              return GestureDetector(
                onTap: () => context.read<RideBookingProvider>().selectVehicle(vehicle),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _getVehicleIcon(vehicle.name, isSelected),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${vehicle.estimatedFare.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _getVehicleIcon(String name, bool isSelected) {
    IconData iconData;
    switch (name.toLowerCase()) {
      case 'bike': iconData = Icons.two_wheeler; break;
      case 'auto': iconData = Icons.electric_rickshaw; break;
      case 'cab': iconData = Icons.local_taxi; break;
      case 'xl cab': iconData = Icons.directions_car; break;
      default: iconData = Icons.directions_car;
    }
    return Icon(iconData, color: isSelected ? Colors.white : Colors.black87, size: 32);
  }
}
