# UPnP Client for dart

### Usage

Direct connect

```dart
import 'package:upnp/upnp.dart';

final discover = DiscoverServiceImp();
final routerUrl = 'http://example:12345/description.xml'
final device = await discover.connect(routerUrl);
final service = await device.lookup(friendlyType: 'WANIPConnection');
final response = await service.actions['GetExternalIPAddress'].invoke({});

print(response['NewExternalIPAddress']);
```

Discover

```dart
import 'package:upnp/upnp.dart';
import 'package:async/async.dart';

final discover = DiscoverServiceImp();

final addresses = (await NetworkInterface.list(type: InternetAddressType.IPv4))
    .map((interface) => interface.addresses)
    .expand((element) => element);

final group = StreamGroup.merge<Device>(addresses.map((e) => discover.discover(e)));

group.listen((device) {
  print(device.name);
  device.allServices.forEach((service) => print(service.friendlyType));
});
```

Check device info

```dart
import 'package:upnp/upnp.dart';

final discover = DiscoverServiceImp();
final device = await discover.connect('http://example:12345/description.xml');
final services = await Future.wait(device.allServices.map((e) => e.getService()));
final types = services
      .map((service) =>
          service.actions.values.map((e) => e.arguments.values.map((e) => e.variable)).expand((element) => element))
      .expand((element) => element)
      .map((element) => element.name)
      .toList();

print(types);
```
