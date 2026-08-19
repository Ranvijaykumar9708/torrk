import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/ride_booking/data/mock_ride_repository.dart';
import 'features/ride_booking/providers/ride_booking_provider.dart';
import 'features/ride_booking/presentation/screens/ride_booking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MockRideRepository>(
          create: (_) => MockRideRepository(),
        ),
        ChangeNotifierProvider<RideBookingProvider>(
          create: (context) => RideBookingProvider(context.read<MockRideRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Torkk',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const RideBookingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
