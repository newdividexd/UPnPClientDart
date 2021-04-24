import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

import '../protocol.dart';
import 'argument.dart';
import 'action.dart';
import 'utils.dart';

Map<String, StateVariable> _parseTypes(XmlElement serviceDef) {
  final states = serviceDef.getElement("serviceStateTable");
  Map<String, StateVariable> types = Map();
  if (states != null) {
    states.findElements("stateVariable").forEach((element) {
      final name = element.getElement("name").text;
      types[name] = StateVariableImp.from(name, element);
    });
  }
  return Map.unmodifiable(types);
}

Map<String, Action> _parseActions(Uri controlUrl, String type, XmlElement serviceDef) {
  final Map<String, StateVariable> types = _parseTypes(serviceDef);
  final actionList = serviceDef.getElement("actionList");
  Map<String, Action> actions = Map();
  if (actionList != null) {
    actionList.findElements("action").forEach((element) {
      final name = element.getElement("name").text;
      actions[name] = ActionImp(name, controlUrl, type, types, element);
    });
  }
  return Map.unmodifiable(actions);
}

class ServiceImp implements Service {
  @override
  final String type;
  @override
  final Map<String, Action> actions;

  ServiceImp(this.type, Uri controlUrl, XmlElement serviceDef)
      : this.actions = _parseActions(controlUrl, type, serviceDef);

  static Future<ServiceImp> from(String type, Uri serviceUrl, Uri controlUrl) async {
    final data = await http.get(serviceUrl);
    final service = XmlDocument.parse(data.body).rootElement;
    return ServiceImp(type, controlUrl, service);
  }

  @override
  String get friendlyType => this.type.friendlyType;
}
