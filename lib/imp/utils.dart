extension StringExtension on String {
  String get friendlyType => this.split(':').reversed.elementAt(1);
}
