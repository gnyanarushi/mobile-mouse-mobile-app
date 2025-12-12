class MotionData {
  final double gyroX;
  final double gyroY;
  final bool leftClick;
  final bool rightClick;

  MotionData({
    required this.gyroX,
    required this.gyroY,
    this.leftClick = false,
    this.rightClick = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "gyroX": gyroX,
      "gyroY": gyroY,
      "leftClick": leftClick,
      "rightClick": rightClick,
    };
  }
}
