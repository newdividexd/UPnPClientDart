import 'dart:io';

enum UPnPDataType {
  boolean,

  unsigned1,
  unsigned2,
  unsigned4,

  integer,
  integer1,
  integer2,
  integer4,

  float,
  float4,
  float8,

  date,
  dateTime,
  dateTimeTz,
  time,
  timeTz,

  char,
  string,
  uri,
  uuid,
  binBase64,
  binHex,
}

class Range<T> {
  final T maximum;
  final T minimum;
  final T setp;
  Range(this.maximum, this.minimum, this.setp);
}

abstract class StateVariable {
  String get name;
  UPnPDataType get type;

  String get initial;
  List<String> get allowed;

  Range get range;
}

abstract class Argument {
  String get name;
  bool get input;
  StateVariable get variable;
}

class UPnPError extends Error {
  final int code;
  final String message;
  UPnPError(this.code, this.message);
  String toString() => "UPnPError: $code $message";
}

abstract class Action {
  String get name;

  Map<String, Argument> get arguments;

  Future<Map<String, String>> invoke(Map<String, String> arguments);
}

abstract class Service {
  String get type;
  String get friendlyType;

  Map<String, Action> get actions;
}

abstract class ServiceDescription {
  String get type;
  String get friendlyType;

  Future<Service> getService();
}

abstract class Device {
  String get name;
  String get udn;
  String get type;
  String get friendlyType;

  Uri get baseUrl;
  Uri get location;

  Map<String, Device> get devices;
  Map<String, ServiceDescription> get services;

  Iterable<ServiceDescription> get allServices;

  Device getDevice({String type, String friendlyType});
  Device lookupDevice({String type, String friendlyType});

  Future<Service> getService({String type, String friendlyType});
  Future<Service> lookup({String type, String friendlyType});
}

abstract class DiscoverService {
  Stream<Device> discover(InternetAddress address);

  Future<Device> connect(String url);
}
