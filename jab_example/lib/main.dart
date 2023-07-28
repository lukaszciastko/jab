import 'package:flutter/widgets.dart';
import 'package:jab/jab.dart';
import 'package:jab_example_app/jab_example_app.dart';

void main() {
  Jab.provideForRoot([
    (_) => Logger(),
  ]);
  runApp(CounterApp());
}

class JabProvider<T> {}

class FactoryProvider<T> extends JabProvider<T> {
  FactoryProvider(this.factory);

  final T Function() factory;
}

final providers = [
  FactoryProvider(() => Logger()),
  JabProvider<Logger>(),
];

final factories = [
  () => Logger(),
];

class NewJab {
  NewJab({
    required this.factories,
    required this.providers,
  });

  final Iterable<JabFactory> Function() factories;
  final Iterable<JabProvider> Function() providers;
}

final newJab = NewJab(
  factories: () => [
    (_) => Logger(),
  ],
  providers: () => [
    FactoryProvider(() => Logger()),
    JabProvider<Logger>(),
  ],
);
