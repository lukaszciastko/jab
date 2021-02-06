library jab;

import 'package:flutter/widgets.dart';

typedef JabProvider<T extends Object> = T Function(T Function<T extends Object>() get);

mixin JabTransientMixin {}

class JabTransientWrapper<T extends Object> {
  JabTransientWrapper(this.instance);

  final T instance;
}

extension JabTransientExtension<T extends Object> on T {
  JabTransientWrapper<T> get transient => JabTransientWrapper<T>(this);
}

/// A callback called before a Service instance is disposed.
///
/// Use this callback to initialize the Service.
typedef OnCreateCallback = void Function(Object service);

/// A callback called before a Service instance is disposed.
///
/// Use this callback to dispose any resources used by the Service.
typedef OnDisposeCallback = void Function(Object service);

mixin JabServiceMixin {
  void onCreate() {}

  void onDispose() {}
}

class JabInjector {
  JabInjector({this.onCreate, this.onDispose, this.parent});

  static final root = JabInjector();

  final OnCreateCallback? onCreate;

  final OnDisposeCallback? onDispose;

  final JabInjector? parent;

  final _providers = <JabProvider>{};

  final _services = <Type, Object>{};

  T get<T extends Object>() {
    if (_services[T] is T) {
      return _services[T] as T;
    }

    return _create<T>() ?? parent?.get<T>() ?? (throw _makeNotFoundException<T>());
  }

  T getTransient<T extends Object>() {
    return _create(transient: true) ?? parent?.getTransient<T>() ?? (throw _makeNotFoundException<T>());
  }

  void register<T extends Object>(JabProvider<T> provider) {
    _providers.add(provider);
  }

  void registerAll(Iterable<JabProvider> providers) {
    _providers.addAll(providers);
  }

  void dispose() {
    for (final service in _services.values) {
      if (service is JabServiceMixin) {
        service.onDispose();
      }
      onDispose?.call(service);
    }

    _providers.clear();
    _services.clear();
  }

  T? _create<T extends Object>({bool? transient}) {
    final provider = _providers.lastWhereOrNull((provider) {
      return provider is JabProvider<T> || provider is JabProvider<JabTransientWrapper<T>>;
    });

    if (provider == null) {
      return null;
    }

    final service = provider(get) as T;

    if (service is JabServiceMixin) {
      service.onCreate();
    }

    if (onCreate != null) {
      onCreate!(service);
    }

    if (service is JabTransientWrapper<T>) {
      return service.instance;
    } else if (service is JabTransientMixin || transient == true) {
      return service;
    } else {
      return _services[T] = service;
    }
  }

  Exception _makeNotFoundException<T>() {
    return Exception('A Service of type $T not found.');
  }
}

extension _IterableExtensions<E> on Iterable<E> {
  E? lastWhereOrNull(bool test(E element)) {
    try {
      return this.lastWhere(test);
    } catch (_) {
      return null;
    }
  }
}

class Jab extends StatefulWidget {
  const Jab({
    Key? key,
    this.injector,
    this.providers,
    this.onCreate,
    this.onDispose,
    required this.child,
  })   : assert(injector == null || (providers == null && onCreate == null && onDispose == null)),
        super(key: key);

  final JabInjector? injector;
  final Iterable<JabProvider> Function()? providers;

  final OnCreateCallback? onCreate;
  final OnDisposeCallback? onDispose;

  final Widget child;

  static JabInjector of(BuildContext context) {
    return _Jab.of(context);
  }

  static T get<T extends Object>(BuildContext context) {
    return of(context).get<T>();
  }

  static T getTransient<T extends Object>(BuildContext context) {
    return of(context).getTransient<T>();
  }

  @override
  JabState createState() => JabState();
}

class _Jab extends InheritedWidget {
  const _Jab({
    Key? key,
    required this.injector,
    required Widget child,
  }) : super(key: key, child: child);

  final JabInjector injector;

  static JabInjector of(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<_Jab>();
    if (element != null) {
      return (element.widget as _Jab).injector;
    } else {
      return JabInjector.root;
    }
  }

  @override
  bool updateShouldNotify(_) {
    return false;
  }
}

class JabState extends State<Jab> {
  JabInjector get injector => _injector;
  late JabInjector _injector;

  @override
  void initState() {
    super.initState();
    _injector = widget.injector ?? _initInjecor();
    if (widget.providers != null) {
      _injector.registerAll(widget.providers!());
    }
  }

  @override
  void dispose() {
    _injector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Jab(
      injector: _injector,
      child: widget.child,
    );
  }

  JabInjector _initInjecor() {
    return JabInjector(
      onCreate: widget.onCreate,
      onDispose: widget.onDispose,
      parent: Jab.of(context),
    );
  }
}

typedef JabServiceWidgetBuilder<T> = Widget Function(BuildContext context, T service);

class JabServiceBuilder<T extends Object> extends StatefulWidget {
  const JabServiceBuilder({
    Key? key,
    this.providers,
    required this.builder,
  }) : super(key: key);

  final Iterable<JabProvider> Function()? providers;
  final JabServiceWidgetBuilder<T> builder;

  @override
  _JabServiceBuilderState<T> createState() => _JabServiceBuilderState<T>();
}

class _JabServiceBuilderState<T extends Object> extends State<JabServiceBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.providers != null) {
      return Jab(
        providers: widget.providers ?? () => [],
        child: Builder(
          builder: (context) {
            return widget.builder(context, Jab.get<T>(context));
          },
        ),
      );
    } else {
      return widget.builder(context, Jab.get<T>(context));
    }
  }
}

typedef JabBlocWidgetBuilder<T> = Widget Function(BuildContext context, T bloc);

class JabBlocBuilder<T extends Object> extends StatefulWidget {
  const JabBlocBuilder({
    Key? key,
    this.providers,
    required this.builder,
  }) : super(key: key);

  final Iterable<JabProvider> Function()? providers;
  final JabBlocWidgetBuilder<T> builder;

  @override
  _JabBlocBuilderState<T> createState() => _JabBlocBuilderState<T>();
}

class _JabBlocBuilderState<T extends Object> extends State<JabBlocBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.providers != null) {
      return Jab(
        providers: widget.providers ?? () => [],
        child: Builder(
          builder: (context) {
            return widget.builder(context, Jab.getTransient<T>(context));
          },
        ),
      );
    } else {
      return widget.builder(context, Jab.getTransient<T>(context));
    }
  }
}

abstract class ViewStateBase {
  BuildContext get context;

  void initState();

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
    _bloc = Jab.getTransient<T>(context);
  }

  void _disposeBloc() {
    if (bloc is Sink) {
      (bloc as Sink).close();
    }
  }
}

mixin ServiceMixin<T extends Object> on ViewStateBase {
  T get service => _service;
  late T _service;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  void _initService() {
    _service = Jab.get<T>(context);
  }
}

abstract class StateWithBloc<T extends StatefulWidget, B extends Object> extends ViewState<T> with BlocMixin<B> {
  StateWithBloc({this.injector});

  final JabInjector? injector;

  @override
  void _initBloc() {
    if (injector != null) {
      _bloc = injector!.getTransient<B>();
    } else {
      super._initBloc();
    }
  }
}

abstract class StateWithService<T extends StatefulWidget, S extends Object> extends ViewState<T> with ServiceMixin<S> {
  StateWithService({this.injector});

  final JabInjector? injector;

  @override
  void _initService() {
    if (injector != null) {
      _service = injector!.get<S>();
    } else {
      super._initService();
    }
  }
}

class JabScope<S extends Object> extends StatefulWidget {
  const JabScope({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _JabScopeState<S> createState() => _JabScopeState<S>();
}

class _JabScopeState<S extends Object> extends State<JabScope<S>> {
  _JabScopeState({this.injector});

  final JabInjector? injector;

  S? get service => _service;
  S? _service;

  @override
  void initState() {
    super.initState();
    if (injector != null) {
      _service = injector!.getTransient<S>();
    } else {
      _service = Jab.get<S>(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _JabScope(service: service, child: widget.child);
  }
}

class _JabScope<T extends Object> extends InheritedWidget {
  _JabScope({Key? key, required this.service, required Widget child}) : super(key: key, child: child);

  final T? service;

  T? maybeOf<T extends Object>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_JabScope<T>>()?.service;
  }

  @override
  bool updateShouldNotify(_JabScope<T> oldWidget) {
    return service != oldWidget.service;
  }
}

extension _InheritedWidgetBuildContextExtension on BuildContext {
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() {
    final widget = getElementForInheritedWidgetOfExactType<T>()?.widget;
    if (widget != null && widget is T) {
      return widget;
    }
  }
}
