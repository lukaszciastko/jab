import 'package:flutter_test/flutter_test.dart';
import 'package:jab/jab.dart';

/// [ServiceA] has no dependencies
class ServiceA {}

/// [ServiceB] depends on [ServiceA]
class ServiceB {
  ServiceB(this.serviceA);

  final ServiceA serviceA;
}

/// [ServiceC] depends on both [ServiceA] and [ServiceB]
class ServiceC {
  ServiceC(this.serviceA, this.serviceB);

  final ServiceA serviceA;
  final ServiceB serviceB;
}

/// [ServiceD] depends on [ServiceC]
class ServiceD {
  ServiceD(this.serviceC);

  final ServiceC serviceC;
}

final providers = <JabFactory>[
  (_) => ServiceA(),
  (jab) => ServiceB(jab()),
  (jab) => ServiceC(jab(), jab()),
  (jab) => ServiceD(jab()),
];

void main() {
  group('JabInjector', () {
    tearDown(() {
      JabInjector.root.clear();
    });

    test('get - ServiceA', () {
      Jab.provideForRoot(providers);
      final serviceA = JabInjector.root.get<ServiceA>();
      expect(serviceA, isA<ServiceA>());
    });

    test('get - ServiceB', () {
      Jab.provideForRoot(providers);
      final serviceB = JabInjector.root.get<ServiceB>();
      expect(serviceB, isA<ServiceB>());
      expect(serviceB.serviceA, isA<ServiceA>());
    });

    test('get - ServiceC', () {
      Jab.provideForRoot(providers);
      final serviceC = JabInjector.root.get<ServiceC>();
      expect(serviceC, isA<ServiceC>());
      expect(serviceC.serviceA, isA<ServiceA>());
      expect(serviceC.serviceB, isA<ServiceB>());
    });

    test('get - all in order', () {
      Jab.provideForRoot(providers);

      final serviceA = JabInjector.root.get<ServiceA>();
      expect(serviceA, isA<ServiceA>());

      final serviceB = JabInjector.root.get<ServiceB>();
      expect(serviceB, isA<ServiceB>());
      expect(serviceB.serviceA, serviceA);

      final serviceC = JabInjector.root.get<ServiceC>();
      expect(serviceC, isA<ServiceC>());
      expect(serviceC.serviceA, serviceA);
      expect(serviceC.serviceB, serviceB);

      final serviceD = JabInjector.root.get<ServiceD>();
      expect(serviceD, isA<ServiceD>());
      expect(serviceD.serviceC, serviceC);
    });

    test('get - all reversed', () {
      Jab.provideForRoot(providers);

      // Note: ServiceD creates all Services.

      final serviceD = JabInjector.root.get<ServiceD>();
      expect(serviceD, isA<ServiceD>());
      expect(serviceD.serviceC, isA<ServiceC>());

      final serviceC = JabInjector.root.get<ServiceC>();
      expect(serviceC, serviceD.serviceC);

      final serviceB = JabInjector.root.get<ServiceB>();
      expect(serviceB, serviceD.serviceC.serviceB);

      final serviceA = JabInjector.root.get<ServiceA>();
      expect(serviceA, serviceD.serviceC.serviceA);
      expect(serviceA, serviceD.serviceC.serviceB.serviceA);
    });

    test('get - onCreate callback in order', () {
      final services = [];
      Jab.setOnCreate(services.add);

      Jab.provideForRoot(providers);

      final serviceA = JabInjector.root.get<ServiceA>();
      expect(services.length, 1);
      expect(services, containsAllInOrder([serviceA]));

      final serviceB = JabInjector.root.get<ServiceB>();
      expect(services.length, 2);
      expect(services, containsAllInOrder([serviceA, serviceB]));

      final serviceC = JabInjector.root.get<ServiceC>();
      expect(services.length, 3);
      expect(services, containsAllInOrder([serviceA, serviceB, serviceC]));

      final serviceD = JabInjector.root.get<ServiceD>();
      expect(services.length, 4);
      expect(services, containsAllInOrder([serviceA, serviceB, serviceC, serviceD]));
    });

    test('get - onCreate callback reversed', () {
      final services = [];
      Jab.setOnCreate(services.add);

      Jab.provideForRoot(providers);

      expectAllABCD() {
        expect(services.length, 4);
        expect(services[0], isA<ServiceA>());
        expect(services[1], isA<ServiceB>());
        expect(services[2], isA<ServiceC>());
        expect(services[3], isA<ServiceD>());
      }

      JabInjector.root.get<ServiceD>();
      expectAllABCD();

      JabInjector.root.get<ServiceC>();
      expectAllABCD();

      JabInjector.root.get<ServiceB>();
      expectAllABCD();

      JabInjector.root.get<ServiceA>();
      expectAllABCD();
    });
  });
}
