import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jab/jab.dart';

void main() {
  runApp(CounterApp());
}

enum CounterEvent { increment, decrement, clear }

class CounterBloc extends ValueNotifier<int> implements Sink<CounterEvent> {
  CounterBloc() : super(0);

  @override
  void add(CounterEvent event) {
    switch (event) {
      case CounterEvent.increment:
        value = value + 1;
        break;
      case CounterEvent.decrement:
        value = value - 1;
        break;
      case CounterEvent.clear:
        value = 0;
        break;
    }
  }

  @override
  void close() {
    dispose();
  }
}

class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (_) => CounterBloc(),
      ],
      child: MaterialApp(
        title: 'Counter',
        home: CounterView(),
      ),
    );
  }
}

class CounterView extends StatefulWidget {
  @override
  _CounterViewState createState() => _CounterViewState();
}

class _CounterViewState extends ViewState<CounterView> with BlocMixin<CounterBloc> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Counter'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: bloc,
        builder: (BuildContext context, int value, _) {
          return Center(
            child: Text(
              value.toString(),
              style: TextStyle(fontSize: 48),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IncrementButton(
            onPressed: () {
              bloc.add(CounterEvent.increment);
            },
          ),
          SizedBox(height: 16),
          DecrementButton(
            onPressed: () {
              bloc.add(CounterEvent.decrement);
            },
          ),
          SizedBox(height: 16),
          ClearButton(
            onPressed: () {
              bloc.add(CounterEvent.clear);
            },
          )
        ],
      ),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({Key key, this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'Increment',
      tooltip: 'Increment',
      child: Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}

class DecrementButton extends StatelessWidget {
  const DecrementButton({Key key, this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'Decrement',
      tooltip: 'Decrement',
      child: Icon(Icons.remove),
      onPressed: onPressed,
    );
  }
}

class ClearButton extends StatelessWidget {
  const ClearButton({Key key, this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'Clear',
      tooltip: 'Clear',
      child: Icon(Icons.delete),
      onPressed: onPressed,
    );
  }
}
