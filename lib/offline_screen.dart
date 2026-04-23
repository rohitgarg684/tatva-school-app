import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'splash_screen.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 80, color: Colors.grey.shade400),
              SizedBox(height: 24),
              Text('No Internet Connection',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700)),
              SizedBox(height: 12),
              Text('Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  final connectivity = await Connectivity().checkConnectivity();
                  if (connectivity != ConnectivityResult.none) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => SplashScreen()));
                  }
                },
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  minimumSize: Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
