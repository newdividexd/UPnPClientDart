import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../protocol.dart';
import 'argument.dart';

Map<String, Argument> _parseArguments(Uri controlUrl, Map<String, StateVariable> types, XmlElement actionDef) {
  final argumentList = actionDef.getElement("argumentList");
  Map<String, Argument> arguments = Map();
  if (argumentList != null) {
    argumentList.findElements("argument").forEach((element) {
      String name = element.getElement("name").text;
      arguments[name] = ArgumentImp(element, types);
    });
  }
  return Map.unmodifiable(arguments);
}

String buildMessage(Map<String, String> inputs, String name, String type) {
  return '<?xml version="1.0"?>' +
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' +
      '<s:Body>' +
      '<u:$name xmlns:u="$type">\n' +
      inputs.entries.map((input) => '<${input.key}>${input.value}</${input.key}>').join('') +
      '</u:$name>' +
      '</s:Body>' +
      '</s:Envelope>';
}

class ActionImp implements Action {
  @override
  final String name;
  @override
  final Map<String, Argument> arguments;

  final Uri _controlUrl;
  final String _serviceType;

  ActionImp(
    this.name,
    this._controlUrl,
    this._serviceType,
    Map<String, StateVariable> types,
    XmlElement actionDef,
  ) : this.arguments = _parseArguments(_controlUrl, types, actionDef);

  @override
  Future<Map<String, String>> invoke(Map<String, String> arguments) async {
    List<int> soapMessage = utf8.encode(buildMessage(arguments, this.name, this._serviceType));
    final response = await http.post(this._controlUrl,
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"${this._serviceType}#${this.name}"',
          'Connection': 'Close',
          'Content-Length': soapMessage.length.toString(),
        },
        body: soapMessage);
    final responseDef = XmlDocument.parse(response.body).rootElement;
    final responseContent = responseDef.firstElementChild.firstElementChild;
    final error = responseContent.findAllElements('UPnPError');
    if (error.isNotEmpty) {
      throw UPnPError(
        int.tryParse(error.first.getElement('errorCode').text),
        error.first.getElement('errorDescription').text,
      );
    } else {
      return Map<String, String>.fromEntries(responseContent.children
          .whereType<XmlElement>()
          .map((element) => MapEntry(element.name.local, element.text)));
    }
  }
}
