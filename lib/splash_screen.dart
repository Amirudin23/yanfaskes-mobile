import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sistem_rs/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> MyHomePage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height - kToolbarHeight,
        width: MediaQuery.sizeOf(context).width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/logo-text.png',
                width: MediaQuery.sizeOf(context).width / 1.5,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.only(bottom: 30),
              child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/bpjs-kesehatan-seeklogo.png',
                width: MediaQuery.sizeOf(context).width / 3,
              ),
            ),
            )
          ],
        ),
      ),
    );
  }
}
