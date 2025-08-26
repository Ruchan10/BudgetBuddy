import 'package:flutter/material.dart';

extension SizeExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double heightPercent(double percent) => screenHeight * (percent / 100);
  double widthPercent(double percent) => screenWidth * (percent / 100);
  double heightDivisor(double divisor) => screenHeight / divisor;
  double widthDivisor(double divisor) => screenWidth / divisor;
}
