library jab_example_app;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jab/jab.dart';
import 'package:rxdart/rxdart.dart';

class Logger implements Sink<String> {
  List<String> get logs => _logs;
  final _logs = <String>[];

  @override
  void add(String data) {
    print('[Logger] $data');
    _logs.add(data);
  }

  @override
  void close() {
    _logs.clear();
  }
}

class CounterStore extends Stream<double> implements Sink<double> {
  CounterStore(this.logger);

  final _controller = BehaviorSubject<double>.seeded(0.0);

  final Logger logger;

  @override
  void add(double data) {
    logger.add('CounterStore.add: $data');
    _controller.add(data);
  }

  @override
  void close() {
    logger.add('CounterStore.close');
    _controller.close();
  }

  void clear() {
    logger.add('CounterStore.clear');
    _controller.add(0);
  }

  @override
  StreamSubscription<double> listen(
    void Function(double event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

enum CounterEvent { increment, decrement }

class CounterBloc implements Sink<CounterEvent> {
  final CounterStore _counterStore;
  final Logger _logger;

  late final StreamSubscription<double> _subscription;
  late double _currentValue;

  CounterBloc(this._counterStore, this._logger) {
    _subscription = _counterStore.listen((value) => _currentValue = value);
  }

  @override
  void add(CounterEvent event) {
    _logger.add('CounterBloc.add: $event');
    switch (event) {
      case CounterEvent.increment:
        _counterStore.add(_currentValue + 1);
        break;
      case CounterEvent.decrement:
        _counterStore.add(_currentValue - 1);
        break;
    }
  }

  @override
  void close() {
    _subscription.cancel();
    _logger.add('CounterBloc.close');
  }
}

class GoldenCounterBloc extends CounterBloc {
  GoldenCounterBloc(CounterStore counterStore, Logger logger) : super(counterStore, logger);

  @override
  void add(CounterEvent event) {
    _logger.add('GoldenCounterBloc.add: $event');
    switch (event) {
      case CounterEvent.increment:
        if (_currentValue == 0) {
          _currentValue = 1;
        }
        _counterStore.add(_currentValue * 1.618);
        break;
      case CounterEvent.decrement:
        _counterStore.add(_currentValue / 1.618);
        break;
    }
  }

  @override
  void close() {
    _subscription.cancel();
    _logger.add('GoldenCounterBloc.close');
  }
}

class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (jab) => CounterStore(jab()),
        (jab) => CounterBloc(jab(), jab()),
      ],
      canCreate: (type) {
        Jab.get<Logger>(context).add('CounterApp.Jab.canCreate: $type');
        return true;
      },
      onCreate: (service) {
        Jab.get<Logger>(context).add('CounterApp.Jab.onCreate: $service');
      },
      onDispose: (service) {
        JabInjector.root.get<Logger>().add('CounterApp.Jab.onDispose: $service');
      },
      child: MaterialApp(
        title: 'Jab Examples',
        routes: {
          '/': (_) => CounterAppHome(),
          '/default': (_) => CounterView(),
          '/golden': (_) => GoldenCounterView(),
        },
      ),
    );
  }
}

class GoldenCounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (jab) => GoldenCounterBloc(jab(), jab()),
      ],
      child: CounterView(),
    );
  }
}

class CounterAppHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jab Examples'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Default Counter'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/default');
            },
          ),
          ListTile(
            title: Text('Golden Counter'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/golden');
            },
          )
        ],
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
        title: Text('Jab Counter'),
      ),
      body: StreamBuilder<double>(
        stream: Jab.get<CounterStore>(context),
        builder: (context, snapshot) {
          return Center(
            child: Text(
              snapshot.data?.toStringAsFixed(2) ?? 'N/A',
              style: TextStyle(fontSize: 48),
              textAlign: TextAlign.center,
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
              Jab.get<CounterStore>(context).clear();
            },
          ),
        ],
      ),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'Increment',
      tooltip: 'Increment',
      child: Icon(Icons.arrow_upward),
      onPressed: onPressed,
    );
  }
}

class DecrementButton extends StatelessWidget {
  const DecrementButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'Decrement',
      tooltip: 'Decrement',
      child: Icon(Icons.arrow_downward),
      onPressed: onPressed,
    );
  }
}

class ClearButton extends StatelessWidget {
  const ClearButton({super.key, required this.onPressed});

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
