import 'package:xml/xml.dart';

import '../protocol.dart';

final Map<String, UPnPDataType> types = Map.unmodifiable({
  'boolean': UPnPDataType.boolean,
  'ui1': UPnPDataType.unsigned1,
  'ui2': UPnPDataType.unsigned2,
  'ui4': UPnPDataType.unsigned4,
  'int': UPnPDataType.integer,
  'i1': UPnPDataType.integer1,
  'i2': UPnPDataType.integer2,
  'i4': UPnPDataType.integer4,
  'float': UPnPDataType.float,
  'r4': UPnPDataType.float4,
  'r8': UPnPDataType.float8,
  'number': UPnPDataType.float8,
  'date': UPnPDataType.date,
  'dateTime': UPnPDataType.dateTime,
  'dateTime.tz': UPnPDataType.dateTime,
  'time': UPnPDataType.time,
  'time.tz': UPnPDataType.time,
  'char': UPnPDataType.char,
  'string': UPnPDataType.string,
  'uri': UPnPDataType.uri,
  'uuid': UPnPDataType.uuid,
  'bin.base64': UPnPDataType.binBase64,
  'bin.hex': UPnPDataType.binHex,
});

Range _getRange(UPnPDataType type, XmlElement element) {
  XmlElement rangeDef = element.getElement('allowedValueRange');
  if (rangeDef != null) {
    String maximum = rangeDef.getElement('maximum')?.text;
    String minimum = rangeDef.getElement('minimum')?.text;
    String step = rangeDef.getElement('step')?.text;
    switch (type) {
      case UPnPDataType.unsigned1:
      case UPnPDataType.unsigned2:
      case UPnPDataType.unsigned4:
      case UPnPDataType.integer:
      case UPnPDataType.integer1:
      case UPnPDataType.integer2:
      case UPnPDataType.integer4:
        return Range<int>(
          maximum == null ? null : int.tryParse(maximum),
          minimum == null ? null : int.tryParse(minimum),
          step == null ? null : int.tryParse(step),
        );
        break;
      case UPnPDataType.float:
      case UPnPDataType.float4:
      case UPnPDataType.float8:
        return Range<double>(
          maximum == null ? null : double.tryParse(maximum),
          minimum == null ? null : double.tryParse(minimum),
          step == null ? null : double.tryParse(step),
        );
        break;
      default:
        return null;
    }
  }
  return null;
}

List<String> _getAllowedList(XmlElement element) {
  XmlElement listDef = element.getElement('allowedValueList');
  if (listDef != null) {
    return listDef.children.where((e) => e is XmlElement).map((e) => e.text).toList();
  }
  return null;
}

class StateVariableImp implements StateVariable {
  @override
  final String name;
  @override
  final UPnPDataType type;

  @override
  final String initial;
  @override
  final List<String> allowed;

  @override
  final Range range;

  StateVariableImp(this.name, this.type, this.initial, this.allowed, this.range);

  static StateVariableImp from(String name, XmlElement element) {
    UPnPDataType type = types[element.getElement('dataType').text];
    String initial = element.getElement('defaultValue')?.text;
    List<String> allowed = _getAllowedList(element);
    Range range = _getRange(type, element);
    return StateVariableImp(name, type, initial, allowed, range);
  }
}

class ArgumentImp implements Argument {
  @override
  final String name;
  @override
  final bool input;
  @override
  final StateVariable variable;

  ArgumentImp(XmlElement element, Map<String, StateVariable> types)
      : this.name = element.getElement("name").text,
        this.input = element.getElement("direction").text == 'in',
        this.variable = types[element.getElement("relatedStateVariable").text];
}
