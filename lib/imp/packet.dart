import 'dart:io';

final InternetAddress broadcast = InternetAddress.tryParse("239.255.255.250");

const List<int> packet = [
  77,
  45,
  83,
  69,
  65,
  82,
  67,
  72,
  32,
  42,
  32,
  72,
  84,
  84,
  80,
  47,
  49,
  46,
  49,
  13,
  10,
  72,
  79,
  83,
  84,
  58,
  50,
  51,
  57,
  46,
  50,
  53,
  53,
  46,
  50,
  53,
  53,
  46,
  50,
  53,
  48,
  58,
  49,
  57,
  48,
  48,
  13,
  10,
  83,
  84,
  58,
  117,
  112,
  110,
  112,
  58,
  114,
  111,
  111,
  116,
  100,
  101,
  118,
  105,
  99,
  101,
  13,
  10,
  77,
  88,
  58,
  50,
  13,
  10,
  77,
  65,
  78,
  58,
  34,
  115,
  115,
  100,
  112,
  58,
  100,
  105,
  115,
  99,
  111,
  118,
  101,
  114,
  34,
  13,
  10,
  13,
  10,
  97,
];