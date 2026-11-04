@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:args_simple/args_simple_io.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late File jsonFile;
  late File yamlFile;
  late File binFile;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('args_simple_test_');
    jsonFile = File('${tmp.path}/config.json')
      ..writeAsStringSync('{"port": 81, "hosts": ["a", "b"]}');
    yamlFile = File('${tmp.path}/config.yaml')
      ..writeAsStringSync('port: 82\nhosts:\n  - c\n  - d\n');
    binFile = File('${tmp.path}/data.bin')..writeAsBytesSync([0, 1, 2, 255]);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  group('ArgsSimpleExtension (dart:io)', () {
    test('arguments as files', () {
      var args = ArgsSimple.parse([
        jsonFile.path,
        yamlFile.path,
        binFile.path,
        tmp.path,
      ]);

      expect(args.argumentAsFile(0)!.path, equals(jsonFile.path));
      expect(
        args.argumentAsFileContentString(0),
        equals(jsonFile.readAsStringSync()),
      );
      expect(
        args.argumentAsFileContentJSON(0),
        equals({
          'port': 81,
          'hosts': ['a', 'b'],
        }),
      );
      expect(
        args.argumentAsFileContentYAML(1),
        equals({
          'port': 82,
          'hosts': ['c', 'd'],
        }),
      );
      expect(args.argumentAsFileContentBytes(2), equals([0, 1, 2, 255]));
      expect(args.argumentAsDirectory(3)!.listSync(), hasLength(3));

      // Missing argument: default, or `null`.
      expect(args.argumentAsFile(9), isNull);
      expect(args.argumentAsFileContentString(9), isNull);
      expect(args.argumentAsFileContentJSON(9), isNull);
      expect(args.argumentAsFileContentYAML(9), isNull);
      expect(args.argumentAsFileContentBytes(9), isNull);
      expect(args.argumentAsDirectory(9), isNull);
      expect(
        args.argumentAsFileContentJSON(9, jsonFile),
        containsPair('port', 81),
      );
      expect(args.argumentAsDirectory(9, tmp)!.path, equals(tmp.path));
    });

    test('options as files', () {
      var args = ArgsSimple.parse([
        '--json',
        jsonFile.path,
        '--yaml',
        yamlFile.path,
        '--bin',
        binFile.path,
        '--dir',
        tmp.path,
      ]);

      expect(args.optionAsFile('json')!.path, equals(jsonFile.path));
      expect(
        args.optionAsFileContentString('json'),
        equals(jsonFile.readAsStringSync()),
      );
      expect(args.optionAsFileContentJSON('json'), containsPair('port', 81));
      expect(args.optionAsFileContentYAML('yaml'), containsPair('port', 82));
      expect(args.optionAsFileContentBytes('bin'), equals([0, 1, 2, 255]));
      expect(args.optionAsDirectory('dir')!.path, equals(tmp.path));

      expect(args.optionAsFile('missing'), isNull);
      expect(args.optionAsFileContentJSON('missing'), isNull);
      expect(args.optionAsFileContentYAML('missing'), isNull);
      expect(args.optionAsFileContentBytes('missing'), isNull);
      expect(
        args.optionAsFileContentYAML('missing', yamlFile),
        containsPair('port', 82),
      );
    });

    test('properties as files', () {
      var args = ArgsSimple.parse([
        '-Pjson=${jsonFile.path}',
        '-Pyaml=${yamlFile.path}',
        '-Pbin=${binFile.path}',
        '-Ddir=${tmp.path}',
      ]);

      expect(args.propertyAsFile('json')!.path, equals(jsonFile.path));
      expect(
        args.propertyAsFileContentString('json'),
        equals(jsonFile.readAsStringSync()),
      );
      expect(args.propertyAsFileContentJSON('json'), containsPair('port', 81));
      expect(args.propertyAsFileContentYAML('yaml'), containsPair('port', 82));
      expect(args.propertyAsFileContentBytes('bin'), equals([0, 1, 2, 255]));
      expect(args.propertyAsDirectory('dir')!.path, equals(tmp.path));

      expect(args.propertyAsFile('missing'), isNull);
      expect(args.propertyAsFileContentJSON('missing'), isNull);
      expect(args.propertyAsFileContentYAML('missing'), isNull);
      expect(args.propertyAsFileContentBytes('missing'), isNull);
      expect(
        args.propertyAsFileContentBytes('missing', binFile),
        equals([0, 1, 2, 255]),
      );
    });

    test('loadEnvironment does not override existing properties', () {
      var env = Platform.environment;
      expect(env, isNotEmpty);

      var existingKey = ArgsSimple.normalizeKey(env.keys.first);
      var args = ArgsSimple.parse(['-P$existingKey=mine']);

      var loaded = args.loadEnvironment();

      expect(loaded, isNot(contains(existingKey)));
      expect(args.propertyAsString(existingKey), equals('mine'));

      for (var k in loaded) {
        expect(args.properties, contains(k));
      }

      // Loading again adds nothing new.
      expect(args.loadEnvironment(), isEmpty);
    });
  });

  group('TypeParserIO', () {
    test('parseFile', () {
      expect(TypeParserIO.parseFile(jsonFile), same(jsonFile));
      expect(TypeParserIO.parseFile(tmp)!.path, equals(tmp.path));
      expect(TypeParserIO.parseFile(' a.txt ')!.path, equals('a.txt'));
      expect(TypeParserIO.parseFile(null), isNull);
      expect(TypeParserIO.parseFile(null, jsonFile), same(jsonFile));
      expect(TypeParserIO.parseFile('  ', jsonFile), same(jsonFile));
    });

    test('parseDirectory', () {
      expect(TypeParserIO.parseDirectory(tmp), same(tmp));
      expect(TypeParserIO.parseDirectory(jsonFile)!.path, jsonFile.path);
      expect(TypeParserIO.parseDirectory(' d ')!.path, equals('d'));
      expect(TypeParserIO.parseDirectory(null), isNull);
      expect(TypeParserIO.parseDirectory(null, tmp), same(tmp));
      expect(TypeParserIO.parseDirectory('', tmp), same(tmp));
    });

    test('parserResolver', () {
      expect(
        TypeParserIO.parserResolver(obj: jsonFile),
        equals(TypeParserIO.parseFile),
      );
      expect(
        TypeParserIO.parserResolver(obj: tmp),
        equals(TypeParserIO.parseDirectory),
      );
      expect(
        TypeParserIO.parserResolver(type: File),
        equals(TypeParserIO.parseFile),
      );
      expect(
        TypeParserIO.parserResolver(t: Directory),
        equals(TypeParserIO.parseDirectory),
      );
      expect(TypeParserIO.parserResolver(type: String), isNull);
      expect(TypeParserIO.parserResolver(obj: 1), isNull);
    });

    test('register', () {
      expect(TypeParser.parserFor<File>(), isNull);

      TypeParserIO.register();
      addTearDown(
        () => TypeParser.unregisterParserResolver(TypeParserIO.parserResolver),
      );

      expect(TypeParser.parserFor<File>(), equals(TypeParserIO.parseFile));
      expect(
        TypeParser.parserFor(obj: tmp),
        equals(TypeParserIO.parseDirectory),
      );

      // With the resolver registered, the generic accessors resolve `File`.
      var args = ArgsSimple.parse(['--f', jsonFile.path]);
      expect(args.option<File>('f')!.path, equals(jsonFile.path));
    });
  });

  group('example CLI', () {
    // Runs `example/args_simple_example.dart` as a real process.
    Future<ProcessResult> runExample(List<String> args) => Process.run(
      Platform.resolvedExecutable,
      ['run', 'example/args_simple_example.dart', ...args],
      stdoutEncoding: utf8,
    );

    test('prints usage when called without arguments', () async {
      var r = await runExample([]);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');
      expect(r.stdout, startsWith('USAGE:'));
    });

    test('parses config file, user, options and flags', () async {
      var r = await runExample([
        jsonFile.path,
        'root',
        '--port',
        '81',
        '--sys-config',
        tmp.path,
        '-verbose',
      ]);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');

      var out = r.stdout as String;
      expect(out, contains('-- Config: {port: 81, hosts: [a, b]}'));
      expect(out, contains('-- User: root'));
      expect(out, contains("-- System Config Dir: Directory: '${tmp.path}'"));
      expect(out, contains('-- Port: 81'));
      expect(out, contains('-- Verbose: true'));
    });

    test('is silent without -verbose', () async {
      var r = await runExample([jsonFile.path]);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');
      expect(r.stdout, isEmpty);
    });

    test('uses defaults for missing and invalid values', () async {
      // Regression: an invalid `--port` used to crash with a `TypeError`.
      var r = await runExample(['not-json.txt', '-verbose', '--port', 'abc']);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');

      var out = r.stdout as String;
      expect(out, contains('-- Config: {}'));
      expect(out, contains('-- User: guest'));
      expect(
        out,
        contains("-- System Config Dir: Directory: '/default/sys-config-dir'"),
      );
      expect(out, contains('-- Port: 8080'));
      expect(out, contains('[not-json.txt, -verbose, --port, abc]'));
    });

    test('a trailing --port without a value uses the default', () async {
      var r = await runExample(['x', '-verbose', '--port']);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');
      expect(r.stdout, contains('-- Port: 8080'));
    });

    test('keeps unicode, spaces and negative numbers as arguments', () async {
      var r = await runExample(['cfg', 'José da Silva 😀', '-verbose', '-5']);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');

      var out = r.stdout as String;
      expect(out, contains('-- User: José da Silva 😀'));
      expect(out, contains('[cfg, José da Silva 😀, -5, -verbose]'));
    });

    test('fails on an invalid JSON config file', () async {
      var bad = File('${tmp.path}/bad.json')..writeAsStringSync('{oops');
      var r = await runExample([bad.path]);
      expect(r.exitCode, isNot(equals(0)));
      expect(r.stderr, contains('FormatException'));
    });

    test('fails on a missing JSON config file', () async {
      var r = await runExample(['${tmp.path}/missing.json']);
      expect(r.exitCode, isNot(equals(0)));
      expect(r.stderr, contains('missing.json'));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('real process argv', () {
    // A script that parses its real `argv` and prints the result as JSON.
    const dumpScript = r'''
import 'dart:convert';
import 'package:args_simple/args_simple.dart';

void main(List<String> argv) {
  var args = ArgsSimple.parse(argv);
  print(jsonEncode({
    'arguments': args.arguments,
    'flags': args.flags.toList(),
    'options': args.options,
    'properties': args.properties,
    'toList': args.toList(),
  }));
}
''';

    late File script;

    setUp(() {
      script = File('${tmp.path}/dump_args.dart')
        ..writeAsStringSync(dumpScript);
    });

    Future<Map<String, dynamic>> dump(List<String> argv) async {
      var packageConfig = File('.dart_tool/package_config.json').absolute;
      var r = await Process.run(Platform.resolvedExecutable, [
        '--packages=${packageConfig.path}',
        script.path,
        ...argv,
      ], stdoutEncoding: utf8);
      expect(r.exitCode, equals(0), reason: '${r.stderr}');
      return jsonDecode(r.stdout as String) as Map<String, dynamic>;
    }

    Map<String, Object> inProcess(List<String> argv) {
      var args = ArgsSimple.parse(argv);
      return {
        'arguments': args.arguments,
        'flags': args.flags.toList(),
        'options': args.options,
        'properties': args.properties,
        'toList': args.toList(),
      };
    }

    const argv = [
      'file name.json',
      '"quoted"',
      "it's",
      'José 😀',
      '',
      '-5',
      '-1.5',
      '-v',
      '-V',
      '--host',
      'a',
      '--host',
      'b=c',
      '--msg',
      '  spaced  ',
      '-Purl=http://h:1/?a=b&c=d',
      '-Dlang=日本語',
      '--',
      '-x',
    ];

    test('parses argv received by a real process like in-process', () async {
      var out = await dump(argv);
      expect(out, equals(inProcess(argv)));

      expect(
        out['arguments'],
        equals([
          'file name.json',
          '"quoted"',
          "it's",
          'José 😀',
          '',
          '-5',
          '-1.5',
        ]),
      );
      expect(out['flags'], equals(['v']));
      expect(
        out['options'],
        equals({
          'host': ['a', 'b=c'],
          'msg': '  spaced  ',
          '': '-x',
        }),
      );
      expect(
        out['properties'],
        equals({'url': 'http://h:1/?a=b&c=d', 'lang': '日本語'}),
      );
    });

    test('toList output passed to a new process round-trips', () async {
      var first = await dump(argv);
      var second = await dump((first['toList'] as List).cast<String>());

      expect(second['arguments'], equals(first['arguments']));
      expect(second['flags'], equals(first['flags']));
      expect(second['options'], equals(first['options']));
      expect(second['properties'], equals(first['properties']));
      expect(second['toList'], equals(first['toList']));
    });

    test('no arguments', () async {
      var out = await dump(const []);
      expect(
        out,
        equals({
          'arguments': [],
          'flags': [],
          'options': {},
          'properties': {},
          'toList': [],
        }),
      );
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
