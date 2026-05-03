import 'package:flutter/material.dart';

class BootstrapFlow extends StatelessWidget {
  const BootstrapFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF091117), Color(0xFF102C36), Color(0xFF08131A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.connected_tv_rounded,
                size: 72,
                color: Color(0xFF6FE0DB),
              ),
              SizedBox(height: 20),
              Text(
                'ImmichTV',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Preparing your TV photo experience...',
                style: TextStyle(color: Color(0xFFB8C8CF)),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
