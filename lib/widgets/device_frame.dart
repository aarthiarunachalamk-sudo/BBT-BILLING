import 'package:flutter/material.dart';

class DeviceFrame extends StatelessWidget {
  final Widget child;

  const DeviceFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375,
      height: 812,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: const Color(0xFF1E293B), width: 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 8,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: Stack(
            children: [
              // Screen content with top padding for status bar
              Positioned.fill(
                top: 40,
                child: child,
              ),

              // Status Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:41',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.signal_cellular_alt, size: 16, color: Colors.black),
                          const SizedBox(width: 4),
                          const Icon(Icons.wifi, size: 16, color: Colors.black),
                          const SizedBox(width: 4),
                          Transform.rotate(
                            angle: 1.5708 * 2, // Rotate battery 180 degrees if needed or just use standard icon
                            child: const Icon(Icons.battery_5_bar, size: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Camera Notch Overlay
              Positioned(
                top: 0,
                left: 87,
                right: 87,
                height: 30,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Home Indicator (Thin bar at the bottom)
              Positioned(
                bottom: 8,
                left: 120,
                right: 120,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
