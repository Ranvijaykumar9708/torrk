import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/ride_booking_provider.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion(this.placeId, this.description);

  @override
  String toString() => description;
}

class LocationInput extends StatelessWidget {
  const LocationInput({super.key});

  static const String _apiKey = 'AIzaSyBcVNOX83jHMMtpeH5Dk9rfUT6d6vGvVM0';

  Future<List<PlaceSuggestion>> _getSuggestions(String query) async {
    if (query.isEmpty) return const [];
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlaceSuggestion(p['place_id'], p['description']))
              .toList();
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return [];
  }

  Future<LatLng?> _getPlaceCoords(String placeId) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  Future<String> _getAddressFromCoords(double lat, double lng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return 'Current Location';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RideBookingProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<PlaceSuggestion>(
          optionsBuilder: (TextEditingValue textEditingValue) =>
              _getSuggestions(textEditingValue.text),
          displayStringForOption: (option) => option.description,
          onSelected: (option) async {
            final coords = await _getPlaceCoords(option.placeId);
            provider.setPickup(option.description, coords);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Where from?',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.circle, color: Colors.black, size: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.black54),
                  onPressed: () async {
                    try {
                      final pos = await Geolocator.getCurrentPosition();
                      final address = await _getAddressFromCoords(pos.latitude, pos.longitude);
                      controller.text = address;
                      provider.setPickup(address, LatLng(pos.latitude, pos.longitude));
                    } catch (_) {}
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (val) => provider.setPickup(val),
            );
          },
        ),
        const SizedBox(height: 12),
        Autocomplete<PlaceSuggestion>(
          optionsBuilder: (TextEditingValue textEditingValue) =>
              _getSuggestions(textEditingValue.text),
          displayStringForOption: (option) => option.description,
          onSelected: (option) async {
            final coords = await _getPlaceCoords(option.placeId);
            provider.setDrop(option.description, coords);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Where to?',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.square, color: Colors.black, size: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (val) => provider.setDrop(val),
            );
          },
        ),
      ],
    );
  }
}
