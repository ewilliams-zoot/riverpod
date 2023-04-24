import 'package:test/test.dart';

import 'hot_reload_utils.dart';

void main() {
  group('Supports family hot-reload', () {
    test(
      'gracefully handles not disposing providers twice when debugReassemble'
      ' is called multiple times on the same contaiener',
      () async {},
    );
    test(
      'disposes of providers in the correct order',
      () async {},
    );

    test(
      'handles changing default values',
      () async {
        final runner = await HotReloadRunner.start(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
String fn(FnRef ref, {int id = 0}) {
  print('Hello from fn($id)');
  ref.onDispose(() {
    print('disposing step1 $id');
  });
  return 'id($id)';
}

Future<void> renderer() async {
  container.listen(
    fnProvider(), (_, value) => print('value: $value'),
    fireImmediately: true,
  );
}
''');

        expect(
          await runner.currentRender.next,
          '''
Hello from fn(0)
value: id(0)''',
        );

        await runner.updateRenders(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
String fn(FnRef ref, {int id = 42}) {
  return 'id2($id)';
}

Future<void> renderer() async {
  print(
    'Provider count before reassemble: '
    '${container.getAllProviderElements().length}',
  );
  container.debugReassemble();
  print(
    'Provider count after reassemble: '
    '${container.getAllProviderElements().length}',
  );

  await container.pump();

  print(container.read(fnProvider()));
}
''');

        expect(
          await runner.currentRender.next,
          '''
Provider count before reassemble: 1
disposing step1 0
Provider count after reassemble: 1
value: id2(0)
id2(42)''',
          reason: 'The provider is maintained, '
              'and active subscriptions are still working',
        );
      },
    );

    test('when adding/removing parameters', () async {
      final runner = await HotReloadRunner.start(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
String fn(FnRef ref, {required int id}) {
  ref.onDispose(() {
    print('disposing step1 $id');
  });
  return 'id($id)';
}

void renderer() {
  container.listen(
    fnProvider(id: 0), (_, value) => print('value: $value'),
    fireImmediately: true,
  );
}
''');

      expect(await runner.currentRender.next, 'value: id(0)');

      await runner.updateRenders(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
String fn(FnRef ref, {required int id2}) => 'id2($id2)';

void renderer() {
  print(
    'Provider count before reassemble: '
    '${container.getAllProviderElements().length}',
  );
  container.debugReassemble();
  print(
    'Provider count after reassemble: '
    '${container.getAllProviderElements().length}',
  );

  container.listen(
    fnProvider(id2: 0), (_, value) => print('value2: $value'),
    fireImmediately: true,
  );
}
''');

      expect(
        await runner.currentRender.next,
        '''
Provider count before reassemble: 1
disposing step1 0
Provider count after reassemble: 0
value2: id2(0)''',
      );
    });
  });

  test(
    'Updates providers if they ref.watch a provider which changed Element',
    () {},
  );

  test(
    'Updates providers if they ref.listen a provider which changed Element',
    () {},
  );

  test('Preserves the state of unedited providers', () {});

  test('Supports switching in/out family', () {});

  test('Supports enabling/disabling autoDispose', () {});

  test('Supports adding/removing overrides', () {});

  test('Supports changing the runtimeType of a provider', () async {
    final runner = await HotReloadRunner.start(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
String fn(FnRef ref) {
  ref.onDispose(() => print('disposing step1'));
  return 'v1';
}

const int x = 0;

Future<void> renderer() async {
  print(x);
  // container.listen(
  //   fnProvider, (_, value) => print('value: $value'),
  //   fireImmediately: true,
  // );
}
''');

    // expect(await runner.currentRender.next, 'value: v1');
    expect(await runner.currentRender.next, '0');

    await runner.updateRenders(r'''
// Reused through hot reload
final container = ProviderContainer();

@riverpod
Future<String> fn(FnRef ref) async => 'v2';

const String x = '1';


Future<void> renderer() async {
  print(x);

  // print(
  //   'Provider count before reassemble: '
  //   '${container.getAllProviderElements().length}',
  // );
  // container.debugReassemble();
  // print(
  //   'Provider count after reassemble: '
  //   '${container.getAllProviderElements().length}',
  // );

  // container.listen(
  //   fnProvider, (_, value) {
  //     print('value2: $value');
  //   },
  //   fireImmediately: true,
  // );
  // await container.read(fnProvider.future);
}
''');

    expect(
      await runner.currentRender.next,
      '''
Provider count before reassemble: 1
disposing step1
Provider count after reassemble: 0
value2: AsyncLoading<String>()
value2: AsyncData<String>(value: v2)
''',
    );
  });

  test('replaces permanent StateReaders with new ones on type change', () {});
  test('deletes temporary StateReaders on type change', () {});
}
