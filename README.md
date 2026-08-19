# Torkk

A minimalist ride-booking application built with Flutter.

## Features

- **Location Selection**: Autocomplete location search and reverse geocoding for current GPS coordinates using Google Maps APIs.
- **Live Routing**: Real-time map rendering of pickup and drop-off points with polyline route drawing using the Google Directions API.
- **Dynamic Fares**: Real-time fare calculation based on actual driving distance and estimated time.
- **Ride Tracking**: Custom vehicle animations simulating the driver approaching the pickup point.
- **Payments**: Integrated Razorpay checkout flow for seamless ride payments.

## Architecture

This project follows a feature-first modular architecture. State management is handled using `Provider` (`ChangeNotifier`).

### Core Components
- `RideBookingProvider`: Manages the entire ride lifecycle, including map controllers, markers, routing geometry, and dynamic fare logic.
- `PaymentService`: Handles Razorpay initialization, checkout events, and callbacks.

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **API Keys**
   Ensure valid keys are provided in the source for:
   - Google Maps API (Geocoding & Directions)
   - Razorpay Test/Live Key (Configured in `PaymentService`)

3. **Run the App**
   ```bash
   flutter run
   ```

*Note: Android requires `minSdkVersion 21` or higher for the Razorpay SDK to compile correctly.*
