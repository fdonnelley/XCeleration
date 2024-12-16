String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60);
  final seconds = ((duration.inMilliseconds / 1000) % 60).toStringAsFixed(2); // Round to 2 decimal places
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  else if (minutes > 0){
    return'$minutes:$seconds';
  }
  else {
    return seconds;
  }
}

String formatDurationWithZeros(Duration duration) {
  final hours = duration.inHours;
  final hoursString = hours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60);
  
  final minutesString = minutes.toString().padLeft(2, '0');
  final seconds = ((duration.inMilliseconds / 1000) % 60).toStringAsFixed(2); // Round to 2 decimal places
  final secondsString = seconds.padLeft(5, '0');
  
  return '$hoursString:$minutesString:$secondsString';
}