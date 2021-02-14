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
    return JabServiceProvider.get(context) ?? of(context).get<T>();
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
    this.isScoped = false,
  }) : super(key: key);

  factory JabServiceBuilder.scoped({
    Key? key,
    Iterable<JabProvider> Function()? providers,
    required JabServiceWidgetBuilder<T> builder,
  }) {
    return JabServiceBuilder(
      key: key,
      providers: providers,
      builder: builder,
      isScoped: true,
    );
  }

  final Iterable<JabProvider> Function()? providers;
  final JabServiceWidgetBuilder<T> builder;
  final bool isScoped;

  @override
  _JabServiceBuilderState<T> createState() => _JabServiceBuilderState<T>();
}

class _JabServiceBuilderState<T extends Object> extends State<JabServiceBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.providers != null) {
      return Jab(
        providers: widget.providers,
        child: Builder(
          builder: _buildWidget,
        ),
      );
    } else {
      return _buildWidget(context);
    }
  }

  Widget _buildWidget(BuildContext context) {
    if (widget.isScoped) {
      return _InitDisposeBuilder<T>(
        init: () => Jab.getTransient<T>(context),
        dispose: (service) {
          if (service is JabServiceMixin) {
            service.onDispose();
          }
        },
        builder: (context, service) {
          return JabServiceProvider(
            service: service,
            child: widget.builder(context, service),
          );
        },
      );
    } else {
      return widget.builder(context, Jab.get<T>(context));
    }
  }
}

class JabServiceProvider<T extends Object> extends InheritedWidget {
  JabServiceProvider({
    Key? key,
    required this.service,
    required Widget child,
  }) : super(key: key, child: child);

  final T service;

  static T? get<T extends Object>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<JabBlocProvider<T>>()?.bloc;
  }

  @override
  bool updateShouldNotify(_) => false;
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
        providers: widget.providers,
        child: Builder(
          builder: _buildWidget,
        ),
      );
    } else {
      return _buildWidget(context);
    }
  }

  Widget _buildWidget(BuildContext context) {
    return _InitDisposeBuilder<T>(
      init: () => Jab.getTransient(context),
      dispose: (bloc) {
        if (bloc is Sink) {
          bloc.close();
        }
      },
      builder: (BuildContext context, T bloc) {
        return JabBlocProvider<T>(
          bloc: bloc,
          child: Builder(
            builder: (context) {
              return widget.builder(context, bloc);
            },
          ),
        );
      },
    );
  }
}

class JabBlocProvider<T extends Object> extends InheritedWidget {
  JabBlocProvider({
    Key? key,
    required this.bloc,
    required Widget child,
  }) : super(key: key, child: child);

  final T bloc;

  static T? get<T extends Object>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<JabBlocProvider<T>>()?.bloc;
  }

  @override
  bool updateShouldNotify(_) => false;
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
  bool _close = true;

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
    final bloc = JabBlocProvider.get<T>(context);
    if (bloc != null) {
      _bloc = bloc;
      _close = false;
    } else {
      _bloc = Jab.getTransient<T>(context);
    }
  }

  void _disposeBloc() {
    if (_close && bloc is Sink) {
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

extension _InheritedWidgetBuildContextExtension on BuildContext {
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() {
    final widget = getElementForInheritedWidgetOfExactType<T>()?.widget;
    if (widget != null && widget is T) {
      return widget;
    }
  }
}

typedef _InitDisposeWidgetBuilder<T> = Widget Function(BuildContext contxt, T obj);

class _InitDisposeBuilder<T> extends StatefulWidget {
  const _InitDisposeBuilder({
    Key? key,
    required this.init,
    required this.dispose,
    required this.builder,
  }) : super(key: key);

  final T Function() init;
  final void Function(T obj) dispose;
  final _InitDisposeWidgetBuilder<T> builder;

  @override
  _InitBuilderState<T> createState() => _InitBuilderState<T>();
}

class _InitBuilderState<T> extends State<_InitDisposeBuilder<T>> {
  late T _obj;

  @override
  void initState() {
    super.initState();
    _obj = widget.init();
  }

  @override
  void dispose() {
    widget.dispose(_obj);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _obj);
  }
}
