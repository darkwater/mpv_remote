String formatSeconds(double seconds) {
  bool negative = seconds < 0;
  seconds = seconds.abs();

  int sec = seconds.floor();

  int hours = sec ~/ 3600;
  int minutes = (sec % 3600) ~/ 60;
  int secs = sec % 60;

  String hoursStr = hours.toString();
  String minutesStr = minutes.toString();
  String secsStr = secs.toString();

  if (minutes < 10) minutesStr = "0" + minutesStr;
  if (secs < 10) secsStr = "0" + secsStr;

  final sign = negative ? "-" : "";

  if (hours == 0) {
    return "$sign$minutesStr:$secsStr";
  } else {
    return "$sign$hoursStr:$minutesStr:$secsStr";
  }
}
