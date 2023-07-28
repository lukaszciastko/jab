library jab;

import 'package:flutter/widgets.dart';

typedef JabFactory<T extends Object> = T Function(T Function<T extends Object>() get);

typedef _JabFactoryProvider = Iterable<JabFactory> Function();

/// A callback called to veto attempts to create a Service.
///
/// If the callback returns false, the Service will not be created.
typedef CanCreate = bool Function(Type type);

/// A callback called before a Service instance is disposed.
///
/// Use this callback to initialize the Service.
typedef OnCreate<T extends Object> = void Function(T service);

/// A callback called before a Service instance is disposed.
///
/// Use this callback to dispose any resources used by the Service.
typedef OnDispose<T extends Object> = void Function(T service);

class _Jab extends InheritedWidget {
  const _Jab({
    required this.jabController,
    required super.child,
  });

  final JabController jabController;

  static JabController? of(BuildContext context) {
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
    super.key,
    required this.providers,
    this.canCreate,
    this.onCreate,
    this.onDispose,
    required this.child,
  });

  /// A callback called to obtain factories defined
  final _JabFactoryProvider providers;

  /// A callback called to veto attempts to create a Service.
  ///
  /// If the callback returns false, the Service will not be created.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  final CanCreate? canCreate;

  /// A callback called before a Service instance is disposed.
  ///
  ///
  /// Use this callback to initialize the Service.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  /// To receive a global callback after a Service is create, consider creating a global callback (`Jab.setOnCreate`).
  final OnCreate? onCreate;

  /// A callback called before a Service instance is disposed.
  ///
  /// Use this callback to dispose any resources used by the Service.
  ///
  /// This callback is only called by the [JabInjector] associated with this [Jab] instance.
  /// To receive a global callback before a Service is dispose, consider creating a global callback (`Jab.setOnDispose`).
  final OnDispose? onDispose;

  final Widget child;

  static JabController? of(BuildContext context) {
    return _Jab.of(context);
  }

  /// Returns an instance of a service of type `T` from the nearest [Jab] up in the widget tree.
  ///
  /// If no instance of the service can be found in the Widget tree,
  /// [Jab] will attempt to find the service in any [JabInjector] which is currently initialized.
  ///
  /// If the Service has not been initialized, a new instance of the Service will be create lazily.
  ///
  /// After the Service has been created, the `Jab.onCreate` callback is called.
  static T get<T extends Object>(BuildContext context) {
    T? service;

    if (JabInjector._useRootAsDefault) {
      // You can explicitly specify to use the root injector.
      // This can be useful especially during Flutter E2E Widget tests.
      try {
        service = JabInjector.root.get<T>();
      } catch (_) {
        service = of(context)?.get<T>();
      }
    } else {
      // This method might be called from a widget tree that does not have an instance of [Jab].
      // In such a case, this method needs to delegate to the root [JabInjector] directly.
      try {
        service = of(context)!.get<T>();
      } catch (_) {
        try {
          service = JabInjector.root.get<T>();
        } catch (_) {
          service = JabInjector.getGlobal<T>();
        }
      }
    }

    if (service != null) {
      return service;
    } else {
      throw Exception('A Service of type $T not found.');
    }
  }

  /// Returns a [JabFactory<T>] of a service of type `T` from the nearest [Jab] up in the widget tree.
  ///
  /// Use this method to obtain a [JabFactory<T>] in order to create and inject the service with a custom provider.
  static JabFactory<T>? getFactory<T extends Object>(BuildContext context) {
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
  T get<T extends Object>();

  JabFactory<T>? getFactory<T extends Object>({bool searchAllAncestors = false});
}

class _JabState extends State<Jab> implements JabController {
  late JabInjector _jab;

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
  T get<T extends Object>() {
    try {
      return _jab.get<T>();
    } catch (_) {
      try {
        return Jab.get<T>(context);
      } catch (_) {
        return JabInjector.root.get<T>();
      }
    }
  }

  JabFactory<T>? getFactory<T extends Object>({bool searchAllAncestors = false}) {
    if (searchAllAncestors) {
      if (JabInjector._useRootAsDefault) {
        return JabInjector.root.getFactory<T>() ?? _jab.getFactory<T>() ?? Jab.getFactory<T>(context);
      } else {
        return _jab.getFactory<T>() ?? Jab.getFactory<T>(context) ?? JabInjector.root.getFactory<T>();
      }
    } else {
      return _jab.getFactory<T>() ?? (throw Exception('A Factory of type $T not found.'));
    }
  }

  void _setUpProviders() {
    _jab.provide(widget.providers());
  }

  void _setUpCallbacks() {
    _jab._canCreate = widget.canCreate;
    _jab._onCreate = widget.onCreate;
    _jab._onDispose = widget.onDispose;
  }
}

class JabInjector {
  JabInjector._(T? Function<T extends Object>()? ownerGet) {
    _ownerGet = ownerGet ?? this.get;
  }

  /// A reference to the `get` method of the [_JabState] that owns this [JabInjector].
  ///
  /// If no [_JabState] owns this [JabInjector] (e.g. if this [JabInjector] is a root injector),
  /// this method is set to the `get` method of this [JabInjector].
  ///
  /// Do not use this method directly - use `_get` instead which throws an error if `T` cannot be found.
  late final T? Function<T extends Object>() _ownerGet;

  /// The root instance of the injector.
  static final JabInjector root = JabInjector._(null);

  static final _global = <Type, Set<Object>>{};

  static bool _useRootAsDefault = false;

  CanCreate? _canCreate;

  OnCreate? _onCreate;

  OnDispose? _onDispose;

  final _factories = <JabFactory>{};

  final _services = <Type, Object>{};

  /// Provide factories ([JabFactory<T>]) for this injector.
  provide(Iterable<JabFactory> factories) {
    _factories.addAll(factories);
  }

  T get<T extends Object>() {
    return _services[T] as T? ?? create<T>() ?? (throw Exception('A Service of type $T not found.'));
  }

  static T? getGlobal<T extends Object>() {
    final global = _global[T];
    if (global != null && global.isNotEmpty) {
      for (final service in global.toList().reversed) {
        if (service is T) return service;
      }
    }
    return null;
  }

  JabFactory<T>? getFactory<T extends Object>() {
    final factories = _factories.whereType<JabFactory<T>>();
    if (factories.isNotEmpty) {
      return factories.last;
    } else {
      return null;
    }
  }

  T? create<T extends Object>() {
    final factory = getFactory<T>();

    if (factory == null) {
      return null;
    }

    if (_canCreate?.call(T) == false) {
      throw Exception('Creating an instance of $T is forbidden.');
    }

    if (!_isRoot() && JabInjector.root._canCreate?.call(T) == false) {
      throw Exception('Creating an instance of $T is forbidden.');
    }

    final service = factory(_get);

    _onCreate?.call(service);

    if (!_isRoot()) {
      JabInjector.root._onCreate?.call(service);
    }

    if (!_isRoot()) {
      _global[T] ??= {};
      _global[T]!.add(service);
    }

    return _services[T] = service;
  }

  /// Remove all factories and existing Service instances from this injector.
  ///
  /// If the Service is an instance of [Sink], the `Sink.close` method will be called.
  void clear() {
    for (final service in _services.values) {
      _onDispose?.call(service);

      if (!_isRoot()) {
        JabInjector.root._onDispose?.call(service);
      }

      if (service is Sink) {
        service.close();
      }

      if (!_isRoot()) {
        _global[service.runtimeType]?.remove(service);
      }
    }

    _factories.clear();
    _services.clear();
  }

  bool _isRoot() {
    return this == JabInjector.root;
  }

  /// The method is passed as a parameter when a [JabFactory] is invoked.
  T _get<T extends Object>() {
    final service = _ownerGet<T>();
    if (service != null) {
      return service;
    } else {
      throw Exception('A Service of type $T not found.');
    }
  }
}

typedef JabWidgetBuilder<T> = Widget Function(BuildContext context, T service);

class JabClient<T extends Object> extends StatefulWidget {
  const JabClient({
    super.key,
    required this.builder,
  });

  final JabWidgetBuilder<T> builder;

  @override
  _JabClientState<T> createState() => _JabClientState<T>();
}

class _JabClientState<T extends Object> extends State<JabClient<T>> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, Jab.get<T>(context));
  }
}

abstract class ViewStateBase {
  BuildContext get context;

  void initState();

  void didChangeDependencies();

  void dispose();
}

abstract class ViewState<T extends StatefulWidget> extends State<T> implements ViewStateBase {}

mixin BlocMixin<T extends Object> on ViewStateBase {
  T get bloc => _bloc;
  late T _bloc;

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

    final get = Jab.of(context)?.get ?? (throw 'No Jab found.');

    _bloc = factory(get);
  }

  void _disposeBloc() {
    if (bloc is Sink) {
      (bloc as Sink).close();
    }
  }
}

class JabProvider<T extends Object> extends StatefulWidget {
  const JabProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  _JabProviderState<T> createState() => _JabProviderState<T>();
}

class _JabProviderState<T extends Object> extends State<JabProvider<T>> {
  @override
  Widget build(BuildContext context) {
    return Jab(
      providers: () => [
        (jab) => Jab.of(context)?.getFactory<T>() ?? (throw 'No factory for Service of type $T found.'),
      ],
      child: widget.child,
    );
  }
}
