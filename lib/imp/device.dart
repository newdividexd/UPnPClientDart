import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../protocol.dart';
import 'service.dart';
import 'utils.dart';

Map<String, Device> _parseDevices(Uri baseUrl, Uri location, XmlElement deviceDef) {
  final deviceList = deviceDef.getElement("deviceList");
  Map<String, Device> devices = Map();
  if (deviceList != null) {
    deviceList.findElements("device").forEach((element) {
      final type = element.getElement("deviceType").text;
      devices[type] = DeviceImp(baseUrl, location, element);
    });
  }
  return Map.unmodifiable(devices);
}

Map<String, ServiceDescription> _getServices(Uri baseUrl, XmlElement deviceDef) {
  final serviceList = deviceDef.getElement("serviceList");
  Map<String, ServiceDescription> services = Map();
  if (serviceList != null) {
    serviceList.findElements("service").forEach((element) {
      final type = element.getElement("serviceType").text;
      final scpd = element.getElement("SCPDURL").text;
      final control = element.getElement("controlURL").text;
      services[type] = ServiceDescriptionImp(type, baseUrl.resolve(scpd), baseUrl.resolve(control));
    });
  }
  return services;
}

class DeviceImp implements Device {
  @override
  final String name;
  @override
  final String udn;
  @override
  final String type;

  @override
  final Uri baseUrl;
  @override
  final Uri location;

  @override
  final Map<String, Device> devices;
  @override
  final Map<String, ServiceDescription> services;

  DeviceImp(this.baseUrl, this.location, XmlElement deviceDef)
      : this.name = deviceDef.getElement("friendlyName").text,
        this.udn = deviceDef.getElement("UDN").text,
        this.type = deviceDef.getElement("deviceType").text,
        this.devices = _parseDevices(baseUrl, location, deviceDef),
        this.services = _getServices(baseUrl, deviceDef);

  @override
  String get friendlyType => this.type.friendlyType;

  static Future<DeviceImp> from(String url) async {
    final location = Uri.parse(url);
    final data = await http.get(location);
    final device = XmlDocument.parse(data.body).rootElement;

    Uri baseUrl;
    final base = device.getElement('URLBase');
    if (base != null) {
      try {
        baseUrl = Uri.parse(base.text);
      } on FormatException {}
    }
    if (baseUrl == null) {
      baseUrl = Uri(scheme: location.scheme, host: location.host, port: location.port);
    }

    return DeviceImp(baseUrl, location, device.getElement("device"));
  }

  @override
  Device getDevice({String type, String friendlyType}) {
    if (type != null) return this.devices[type];
    final key = this.devices.keys.firstWhere(
          (d) => d.friendlyType == friendlyType,
          orElse: () => null,
        );
    return this.devices[key];
  }

  @override
  Device lookupDevice({String type, String friendlyType}) {
    Device device = this.getDevice(type: type, friendlyType: friendlyType);
    if (device != null) {
      return device;
    }
    final devices = this.devices.values.iterator;
    while (devices.moveNext()) {
      device = devices.current.lookupDevice(type: type, friendlyType: friendlyType);
      if (device != null) {
        return device;
      }
    }
    return null;
  }

  @override
  Future<Service> getService({String type, String friendlyType}) {
    if (friendlyType != null) {
      type = this.services.keys.firstWhere(
            (s) => s.friendlyType == friendlyType,
            orElse: () => null,
          );
    }
    if (type == null) return null;
    return this.services[type].getService();
  }

  @override
  Future<Service> lookup({String type, String friendlyType}) async {
    Service service = await this.getService(
      type: type,
      friendlyType: friendlyType,
    );
    if (service != null) {
      return service;
    }
    final devices = this.devices.values.iterator;
    while (devices.moveNext()) {
      service = await devices.current.lookup(
        type: type,
        friendlyType: friendlyType,
      );
      if (service != null) {
        return service;
      }
    }
    return null;
  }

  @override
  Iterable<ServiceDescription> get allServices => this
      .services
      .values
      .followedBy(this.devices.values.map((device) => device.allServices).expand((element) => element));
}

class ServiceDescriptionImp extends ServiceDescription {
  @override
  final String type;

  Future<Service> _service;
  Uri _scpdUrl;
  Uri _controlUrl;

  ServiceDescriptionImp(this.type, this._scpdUrl, this._controlUrl);

  @override
  Future<Service> getService() {
    if (this._service == null) {
      this._service = ServiceImp.from(type, this._scpdUrl, this._controlUrl);
      this._scpdUrl = null;
      this._controlUrl = null;
    }
    return this._service;
  }

  @override
  String get friendlyType => this.type.friendlyType;
}
