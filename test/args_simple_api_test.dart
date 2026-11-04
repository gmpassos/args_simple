import 'package:args_simple/args_simple.dart';
import 'package:test/test.dart';

void main() {
  group('ArgsSimple.parse', () {
    test('repeated option collects values', () {
      var args = ArgsSimple.parse(['--a', '1', '--A', '2', '--a', '3', '--b']);
      expect(
        args.options,
        equals({
          'a': ['1', '2', '3'],
          'b': '',
        }),
      );
      expect(args.optionAsList('a'), equals(['1', '2', '3']));
    });

    test('negative numbers are arguments, not flags', () {
      var args = ArgsSimple.parse(['-1.5', '-2', '-v']);
      expect(args.arguments, equals(['-1.5', '-2']));
      expect(args.flags, equals({'v'}));
      expect(args.argumentAsDouble(0), equals(-1.5));
      expect(args.argumentAsInt(1), equals(-2));
    });

    test('properties with `=` and `:` delimiters', () {
      var args = ArgsSimple.parse(['-Pa=1', '-Db:two', '-DFlag', '-Pc=x=y']);
      expect(
        args.properties,
        equals({'a': '1', 'b': 'two', 'flag': '', 'c': 'x=y'}),
      );
    });

    test('keys are normalized', () {
      var args = ArgsSimple.parse(['--Sys-Config', '/etc', '-Fast_Mode']);
      expect(args.options, equals({'sysconfig': '/etc'}));
      expect(args.flags, equals({'fastmode'}));
      expect(args.optionAsString('sys-config'), equals('/etc'));
      expect(args.optionAsString('SYS_CONFIG'), equals('/etc'));
      expect(args.flag('fast-mode'), isTrue);
      expect(args.flag('Fast_Mode'), isTrue);
    });
  });

  group('ArgsSimple.fromJson', () {
    test('from List<String>', () {
      var args = ArgsSimple.fromJson(['a', '--b', '1', '-c']);
      expect(args.arguments, equals(['a']));
      expect(args.options, equals({'b': '1'}));
      expect(args.flags, equals({'c'}));
    });

    test('from List of non-String values', () {
      var args = ArgsSimple.fromJson([1, '-v', 2.5]);
      expect(args.arguments, equals(['1', '2.5']));
      expect(args.flags, equals({'v'}));
    });

    test('from Map', () {
      var args = ArgsSimple.fromJson({'port': 81, 'host': null});
      expect(args.options, equals({'port': 81, 'host': ''}));
      expect(args.optionAsInt('port'), equals(81));
      expect(args.arguments, isEmpty);
    });

    test('from scalar', () {
      var args = ArgsSimple.fromJson('only');
      expect(args.arguments, equals(['only']));
    });

    test('fromEncodedJson', () {
      expect(
        ArgsSimple.fromEncodedJson('["x", "--n", "3"]').optionAsInt('n'),
        equals(3),
      );
      expect(
        ArgsSimple.fromEncodedJson('{"n": 4}').optionAsInt('n'),
        equals(4),
      );
    });
  });

  group('ArgsSimple accessors', () {
    late ArgsSimple args;

    setUp(() {
      args = ArgsSimple.parse([
        '10',
        '2.5',
        'yes',
        'a,b,a',
        'k=v;n=1',
        'file.json',
        '--int',
        '7',
        '--double',
        '0.5',
        '--bool',
        'no',
        '--list',
        'x;y',
        '--map',
        'a:1',
        '-flag',
        '-Pint=9',
        '-Pdouble=1.25',
        '-Pbool=true',
        '-Plist=p,q',
        '-Pmap=z=0',
        '-Pname=app.yaml',
      ]);
    });

    test('arguments', () {
      expect(args.argumentAsInt(0), equals(10));
      expect(args.argumentAsDouble(1), equals(2.5));
      expect(args.argumentAsBool(2), isTrue);
      expect(args.argumentAsList(3), equals(['a', 'b', 'a']));
      expect(args.argumentAsSet(3), equals({'a', 'b'}));
      expect(args.argumentAsMap(4), equals({'k': 'v', 'n': '1'}));
      expect(args.argumentAsString(5), equals('file.json'));

      // Type inferred from the default value:
      expect(args.argument(0, 0), equals(10));
      expect(args.argument(2, false), isTrue);
      // No parser for `dynamic`: the raw value is returned.
      expect(args.argument(0), equals('10'));
      expect(args.argument<int>(0, null, (o) => int.parse('$o') * 2), 20);

      expect(args.argumentAsInt(99), isNull);
      expect(args.argumentAsInt(99, 5), equals(5));
      expect(args.argumentAsString(99, 'd'), equals('d'));
    });

    test('argumentMatches', () {
      expect(args.argumentMatches(5, RegExp(r'\.json$')), isTrue);
      expect(args.argumentMatches(5, 'file'), isTrue);
      expect(args.argumentMatches(5, 'json'), isFalse);
      expect(args.argumentMatches(99, 'file'), isFalse);
    });

    test('options', () {
      expect(args.optionAsInt('int'), equals(7));
      expect(args.optionAsDouble('double'), equals(0.5));
      expect(args.optionAsBool('bool'), isFalse);
      expect(args.optionAsList('list'), equals(['x', 'y']));
      expect(args.optionAsSet('list'), equals({'x', 'y'}));
      expect(args.optionAsMap('map'), equals({'a': '1'}));
      expect(args.option('int', 0), equals(7));

      expect(args.optionAsInt('missing'), isNull);
      expect(args.optionAsInt('missing', 3), equals(3));
      expect(args.optionAsBool('missing', true), isTrue);
    });

    test('optionMatches', () {
      expect(args.optionMatches('list', RegExp(r'y$')), isTrue);
      expect(args.optionMatches('list', 'x'), isTrue);
      expect(args.optionMatches('list', 'y'), isFalse);
      expect(args.optionMatches('missing', 'x'), isFalse);
    });

    test('properties', () {
      expect(args.propertyAsInt('int'), equals(9));
      expect(args.propertyAsDouble('double'), equals(1.25));
      expect(args.propertyAsBool('bool'), isTrue);
      expect(args.propertyAsList('list'), equals(['p', 'q']));
      expect(args.propertyAsSet('list'), equals({'p', 'q'}));
      expect(args.propertyAsMap('map'), equals({'z': '0'}));
      expect(args.propertyAsString('name'), equals('app.yaml'));
      expect(args.property('int', 0), equals(9));

      expect(args.propertyAsString('missing'), isNull);
      expect(args.propertyAsString('missing', 'd'), equals('d'));
    });

    test('propertyMatches', () {
      expect(args.propertyMatches('name', RegExp(r'\.ya?ml$')), isTrue);
      expect(args.propertyMatches('name', 'app'), isTrue);
      expect(args.propertyMatches('name', 'yaml'), isFalse);
      expect(args.propertyMatches('missing', 'app'), isFalse);
    });

    test('flags', () {
      expect(args.flag('flag'), isTrue);
      expect(args.flag('FLAG'), isTrue);
      expect(args.flag('other'), isFalse);

      expect(args.flagOr('flag', false), isTrue);
      expect(args.flagOr('Flag', null), isTrue);
      expect(args.flagOr('other', null), isNull);
      expect(args.flagOr('other', false), isFalse);
    });
  });

  group('ArgsSimple mutation', () {
    test('add/put normalize keys', () {
      var args = ArgsSimple();
      expect(args.isEmpty, isTrue);

      args.addArgument('arg0');
      args.putOption('Out-Dir', '/tmp/out');
      args.addFlag('Dry-Run');
      args.putProperty('Env.Name', 'prod');

      expect(args.isNotEmpty, isTrue);
      expect(args.arguments, equals(['arg0']));
      expect(args.options, equals({'outdir': '/tmp/out'}));
      expect(args.flags, equals({'dryrun'}));
      expect(args.properties, equals({'envname': 'prod'}));
    });

    test('exposed collections are unmodifiable', () {
      var args = ArgsSimple.parse(['a', '--b', '1', '-c', '-Pd=2']);
      expect(() => args.arguments.add('x'), throwsUnsupportedError);
      expect(() => args.options['x'] = 'y', throwsUnsupportedError);
      expect(() => args.flags.add('x'), throwsUnsupportedError);
      expect(() => args.properties['x'] = 'y', throwsUnsupportedError);
    });
  });

  group('ArgsSimple serialization', () {
    test('normalizeKey', () {
      expect(ArgsSimple.normalizeKey('Foo-Bar_baz.1'), equals('foobarbaz1'));
      expect(ArgsSimple.normalizeKey(' A b '), equals('ab'));
    });

    test('toList round-trips through parse', () {
      var original = ArgsSimple.parse([
        'a',
        '--x',
        '1',
        '-f',
        '-Pp=v',
        'b',
        '--x',
        '2',
      ]);

      var list = original.toList();
      expect(list, equals(['a', 'b', '-f', '--x', '1', '--x', '2', '-Pp=v']));

      var parsed = ArgsSimple.parse(list);
      expect(parsed.toJson(), equals(original.toJson()));
    });

    test('toJson and toString', () {
      expect(ArgsSimple().toJson(), isEmpty);

      var args = ArgsSimple.parse(['a', '-f']);
      expect(
        args.toJson(),
        equals({
          'arguments': ['a'],
          'flags': {'f'},
        }),
      );
      expect(args.toString(), equals('[a, -f]'));
    });
  });
}
