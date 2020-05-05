# Jab

Jab is a simple hierarchical dependency injection framework for Flutter. It offers easy dependency overriding in the Widget tree and provides out-of-the-box support for the BLoC pattern.

## Getting Started

In the Jab Example app, there are three main services: `Logger`, `CounterStore` and `CounterBloc`. `Logger` has no dependencies. `CounterStore` depends on the `Logger`, and `CounterBloc` depends on both the `Logger` and the `CounterStore`.

### Resolving Dependencies

All services in Jab should be provided using a `JabFactory<T>` method that passes an injector function as a parameter and is supposed to return an instance of a service, e.g:

```dart
final providers = <JabFactory>[
  (jab) => ServiceA(),
  (jab) => ServiceB(jab()),
  (jab) => ServiceC(jab(), jab()),
  (jab) => ServiceD(jab()),
];
```
 
### Root Injector

The `Logger` service is initialized by the root injector before the application starts:

```dart
void main() {
  Jab.provideForRoot([
    (_) => Logger(),
  ]);
  runApp(CounterApp());
}
```

Consider using the root injector for singleton services in your application.

The root injector can also be used during testing.

### Tree Injector

The two remaining services (`CounterStore` and `CounterBloc`) are provided to a `Jab` that wraps the application in the widget tree:

```dart
class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (jab) => CounterStore(jab()),
        (jab) => CounterBloc(jab(), jab()),
      ],
      child: MaterialApp(
        title: 'Jab Examples',
      ),
    );
  }
}
```

Consider using widget tree injection to provide your services with a lifecycle (for example, you can create a Jab that wraps a module in your app that can only be accessed by authenticated users).

If your service implements `Sink` (e.g. `Sink<void>`), `Jab` will call the `close` method on it before the `Jab` instance gets disposed (i.e. is removed from the widget tree).

### Getting a Service

To obtain an instance of a service in your code, you can call the `Jab.get<Service>(context)` function. For example:

```dart
ClearButton(
  onPressed: () {
    Jab.get<CounterStore>(context).clear();
  },
)
```

## Jab with BLoC

If you're using Jab with the Business Logic Component pattern, consider providing an instance of the Jab using the `BlocMixin<T>` with your `State`:

```dart
class _CounterViewState extends ViewState<CounterView> with BlocMixin<CounterBloc> {
```

**Important**: insted of extending `State`, you need to extend `ViewState` from the Jab library.

Once you use the`BlocMixin` in your `ViewState`, you can simply call the `bloc` property to acces your business component:

```dart
IncrementButton(
  onPressed: () {
    bloc.add(CounterEvent.increment);
  },
)
```

You can use `Jab` with both a custom BloC implementation and with the `bloc` library. If you create your BloC yourself, consider making it implement `Sink<void>`. Jab will detect that your BloC implements a `Sink` and correctly dispose it by calling the `close` method when the `ViewState` is removed from the widget tree.

## Overriding Dependencies

Anywhere in the widget tree, you can override an existing service and provide a custom implementation. The Jab Example app provides a custom implementation of the `CounterBloc` called `GoldenCounterBloc`:

```dart
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
```

Thanks to hierarchical depency injection, the `CounterView` class doesn't have to change to reflect the differences in the implementation of the two BLoCs.