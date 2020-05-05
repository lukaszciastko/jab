library jab;

import 'package:flutter/widgets.dart';

typedef JabFactory<T extends Object> = T Function(T Function<T>() get);

typedef _JabFactoryProvider = Iterable<JabFactory> Function();

/// A callback called to veto attempts to create a Service.
///
/// If the callback returns false, the Service will not be created.
typedef CanCreate = bool Function(Type type);

/// A callback called before a Service instance is disposed.
///
/// Use this callback to initialize the Service.
typedef OnCreate = void Function(Object service);

/// A callback called before a Service instance is disposed.
///
/// Use this callback to dispose any resources used by the Service.
typedef OnDispose = void Function(Object service);

class _Jab extends InheritedWidget {
  const _Jab({
    Key key,
    @required this.jabController,
    @required Widget child,
  })  : assert(jabController != null && child != null),
        super(key: key, child: child);

  final JabController jabController;

  static JabController of(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<_Jab>();
    if (element != null) {
      return (element.widget as _Jab).jabController;
    } else {
      return null;
    }
  }

  @override
  bool updateShouldNotify(_Jab old) {
    return false;
  }
}

/// [Jab] is a hierarchical dependency injection framework for Flutter.
class Jab extends StatefulWidget {
  const Jab({
    Key key,
    @required this.providers,
    this.canCreate,
    this.onCreate,
    this.onDispose,
    this.child,
  }) : super(key: key);

  /// A callback called to obtain factories defined
  final _JabFactoryProvider providers;

  /// A callback called to veto attempts to create a Service.
  ///
  /// If the callback returns false, the Service will not be created.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  final CanCreate canCreate;

  /// A callback called before a Service instance is disposed.
  ///
  ///
  /// Use this callback to initialize the Service.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  /// To receive a global callback after a Service is create, consider creating a global callback (`Jab.setOnCreate`).
  final OnCreate onCreate;

  /// A callback called before a Service instance is disposed.
  ///
  /// Use this callback to dispose any resources used by the Service.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  /// To receive a global callback before a Service is dispose, consider creating a global callback (`Jab.setOnDispose`).
  final OnDispose onDispose;

  final Widget child;

  static JabController of(BuildContext context) {
    return _Jab.of(context);
  }

  /// Returns an instance of a service of type `T` from the nearest [Jab] up inI the widget tree.
  ///
  /// If the Service has not been initialized, a new instance of the Service will be create lazily.
  ///
  /// After the Service has been created, the `Jab.onCreate` callback is called.
  static T get<T>(BuildContext context, {bool returnNullIfNotFound = false}) {
    T service;

    if (JabInjector._useRootAsDefault) {
      // You can explicitly specify to use the root injector.
      // This can be useful especially during Flutter E2E Widget tests.
      service = JabInjector.root.get<T>() ?? of(context)?.get<T>();
    } else {
      // This method might be called from a widget tree that does not have an instance of [Jab].
      // In such a case, this method needs to delegate to the root [JabInjector] directly.
      service = of(context)?.get<T>() ?? JabInjector.root.get<T>();
    }

    if (service != null) {
      return service;
    } else if (returnNullIfNotFound) {
      return null;
    } else {
      throw Exception('A Service of type $T not found.');
    }
  }

  /// Returns a [JabFactory<T>] of a service of type `T` from the nearest [Jab] up in the widget tree.
  ///
  /// Use this method to obtain a [JabFactory<T>] in order to create and inject the service with a custom provider.
  static JabFactory<T> getFactory<T>(BuildContext context) {
    return of(context)?.getFactory<T>(searchAllAncestors: true);
  }

  /// Set up a global callback to veto attempts to create a Service.
  ///
  /// This callback can veto any attempt to create a Service by any any [JabInjector] in the widget tree.
  static void setCanCreate(CanCreate canCreate) {
    JabInjector.root._canCreate = canCreate;
  }

  /// Set up a global callback that will be called after a Service instance is created.
  ///
  /// This callback is called for any Service created by any [JabInjector] in the widget tree.
  static void setOnCreate(OnCreate onCreate) {
    JabInjector.root._onCreate = onCreate;
  }

  /// Set up a global callback that will be called before a Service instance is dispose.
  ///
  /// his callback is called for any Service disposed by any [JabInjector] in the widget tree.
  static void setOnDispose(OnDispose onDispose) {
    JabInjector.root._onDispose = onDispose;
  }

  /// Provide factories ([JabFactory<T>]) for the root injector.
  ///
  /// Consider using this method to provider factories for custom providers (make sure to veto
  /// any attempt to create an instance of a specific service by setting the [CanCreate] callback).
  ///
  /// Consider using this method in testing.
  static void provideForRoot(Iterable<JabFactory> factories) {
    JabInjector.root.provide(factories);
  }

  /// If set to true, Jab will always try to resolve dependencies using the root injector.
  /// This can be useful especially during Flutter E2E Widget tests (e.g. to mock the default HTTP Client).
  static void useRootAsDefault([bool useRootAsDefault = true]) {
    JabInjector._useRootAsDefault = useRootAsDefault;
  }

  /// Remove all factories and existing Service instances from the root [JabInjector].
  ///
  /// Consider using this method in testing.
  static void clearRoot() {
    JabInjector.root.clear();
  }

  @override
  _JabState createState() => _JabState();
}

abstract class JabController {
  T get<T>();

  JabFactory<T> getFactory<T>({bool searchAllAncestors = false});
}

class _JabState extends State<Jab> implements JabController {
  JabInjector _jab;

  @override
  void initState() {
    super.initState();
    _jab = JabInjector._(get);
    _setUpProviders();
    _setUpCallbacks();
  }

  @override
  void didUpdateWidget(Jab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setUpCallbacks();
  }

  @override
  void dispose() {
    _jab.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Jab(jabController: this, child: widget.child);
  }

  /// Returns an instance of a service of type `T` from this or the nearest [Jab] up in the widget tree.
  ///
  /// If the Service has not been initialized, a new instance of the Service will be create lazily.
  T get<T>() {
    return _jab.get<T>() ?? Jab.get<T>(context, returnNullIfNotFound: true) ?? JabInjector.root.get<T>();
  }

  JabFactory<T> getFactory<T>({bool searchAllAncestors = false}) {
    if (searchAllAncestors) {
      if (JabInjector._useRootAsDefault) {
        return JabInjector.root.get<T>() ?? _jab.getFactory<T>() ?? Jab.getFactory<T>(context);
      } else {
        return _jab.getFactory<T>() ?? Jab.getFactory<T>(context) ?? JabInjector.root.get<T>();
      }
    } else {
      return _jab.getFactory<T>();
    }
  }

  void _setUpProviders() {
    if (widget.providers != null) {
      _jab.provide(widget.providers());
    }
  }

  void _setUpCallbacks() {
    _jab._canCreate = widget.canCreate;
    _jab._onCreate = widget.onCreate;
    _jab._onDispose = widget.onDispose;
  }
}

class JabInjector {
  JabInjector._(this._ownerGet) {
    if (_ownerGet == null) _ownerGet = this.get;
  }

  /// A reference to the `get` method of the [_JabState] that owns this [JabInjector].
  ///
  /// If no [_JabState] owns this [JabInjector] (e.g. if this [JabInjector] is a root injector),
  /// this method is set to the `get` method of this [JabInjector].
  ///
  /// Do not use this method directly - use `_get` instead which throws an error if `T` cannot be found.
  T Function<T>() _ownerGet;

  /// The root instance of the injector.
  static final JabInjector root = JabInjector._(null);

  static bool _useRootAsDefault = false;

  CanCreate _canCreate;

  OnCreate _onCreate;

  OnDispose _onDispose;

  final _factories = <JabFactory>{};

  final _services = <Type, Object>{};

  /// Provide factories ([JabFactory<T>]) for this injector.
  provide(Iterable<JabFactory> factories) {
    _factories.addAll(factories);
  }

  T get<T>() {
    return _services[T] ?? create<T>();
  }

  JabFactory<T> getFactory<T>() {
    return _factories.lastWhereOrNull((f) => f is JabFactory<T>);
  }

  T create<T>() {
    final factory = getFactory<T>();

    if (factory == null) {
      return null;
    }

    if (_canCreate != null && !_canCreate(T)) {
      throw Exception('Creating an instance of $T is forbidden.');
    }

    if (!_isRoot() && JabInjector.root._canCreate != null && !JabInjector.root._canCreate(T)) {
      throw Exception('Creating an instance of $T is forbidden.');
    }

    final service = factory(_get);

    if (_onCreate != null) {
      _onCreate(service);
    }

    if (!_isRoot() && JabInjector.root._onCreate != null) {
      JabInjector.root._onCreate(service);
    }

    return _services[T] = service;
  }

  /// Remove all factories and existing Service instances from this injector.
  ///
  /// If the Service is an instance of [Sink], the `Sink.close` method will be called.
  void clear() {
    for (final service in _services.values) {
      if (_onDispose != null) {
        _onDispose(service);
      }

      if (!_isRoot() && JabInjector.root._onDispose != null) {
        JabInjector.root._onDispose(service);
      }

      if (service is Sink) {
        service.close();
      }
    }

    _factories.clear();
    _services.clear();
  }

  bool _isRoot() {
    return this == JabInjector.root;
  }

  /// The method is passed as a parameter when a [JabFactory] is invoked.
  T _get<T>() {
    final service = _ownerGet<T>();
    if (service != null) {
      return service;
    } else {
      throw Exception('A Service of type $T not found.');
    }
  }
}

typedef JabWidgetBuilder<T> = Widget Function(BuildContext context, T service);

class JabClient<T> extends StatefulWidget {
  const JabClient({
    Key key,
    @required this.builder,
  }) : super(key: key);

  final JabWidgetBuilder<T> builder;

  @override
  _JabClientState<T> createState() => _JabClientState<T>();
}

class _JabClientState<T> extends State<JabClient<T>> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, Jab.get<T>(context));
  }
}

extension _IterableExtensions<E> on Set<E> {
  E lastWhereOrNull(bool test(E element)) {
    try {
      return this.lastWhere(test);
    } catch (e) {
      return null;
    }
  }
}

abstract class ViewStateBase {
  BuildContext get context;

  void initState();

  void dispose();
}

abstract class ViewState<T extends StatefulWidget> extends State<T> implements ViewStateBase {}

mixin BlocMixin<T> on ViewStateBase {
  T get bloc => _bloc;
  T _bloc;

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  @override
  void dispose() {
    _disposeBloc();
    super.dispose();
  }

  void _initBloc() {
    final factory = Jab.getFactory<T>(context);

    if (factory == null) {
      throw 'No factory for BloC of type $T found.';
    }

    _bloc = factory(Jab.of(context).get);
  }

  void _disposeBloc() {
    if (bloc is Sink) {
      (bloc as Sink).close();
    }
  }
}

class JabProvider<T> extends StatefulWidget {
  const JabProvider({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _JabProviderState<T> createState() => _JabProviderState<T>();
}

class _JabProviderState<T> extends State<JabProvider<T>> {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (jab) => Jab.of(context).getFactory<T>(),
      ],
    );
  }
}
