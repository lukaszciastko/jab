import 'package:flutter/widgets.dart';
import 'package:jab/jab.dart';
import 'package:jab_example_app/jab_example_app.dart';

void main() {
  Jab.provideForRoot([
    (_) => Logger(),
  ]);
  runApp(CounterApp());
}
