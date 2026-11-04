import 'package:args_simple/args_simple.dart';
import 'package:test/test.dart';

/// Parses [args], serializes with `toList` and parses again, returning both.
(ArgsSimple, ArgsSimple) roundTrip(List<String> args) {
  var a = ArgsSimple.parse(args);
  var b = ArgsSimple.parse(a.toList());
  return (a, b);
}

void main() {
  group('ArgsSimple.parse: empty input', () {
    test('no arguments', () {
      for (var args in [ArgsSimple.parse(), ArgsSimple.parse(const [])]) {
        expect(args.isEmpty, isTrue);
        expect(args.isNotEmpty, isFalse);
        expect(args.arguments, isEmpty);
        expect(args.flags, isEmpty);
        expect(args.options, isEmpty);
        expect(args.properties, isEmpty);
        expect(args.toList(), isEmpty);
        expect(args.toJson(), isEmpty);
        expect(args.toString(), equals('[]'));
      }
    });

    test('empty string is a (positional) argument', () {
      var args = ArgsSimple.parse(['', 'a', '']);
      expect(args.arguments, equals(['', 'a', '']));
      expect(args.isNotEmpty, isTrue);
      expect(args.argumentAsString(0), equals(''));
      expect(args.argumentAsInt(0, 7), equals(7));
      expect(args.argumentAsBool(0, true), isTrue);
      expect(args.argumentAsList(0), isNull);
      expect(args.argumentAsMap(0), isNull);
    });
  });

  group('ArgsSimple.parse: `--` and options', () {
    test('`--` is not a terminator: it is an option with an empty key', () {
      var args = ArgsSimple.parse(['--', '-v', 'x']);
      expect(args.options, equals({'': '-v'}));
      expect(args.flags, isEmpty);
      expect(args.arguments, equals(['x']));
    });

    test('a trailing `--` gets an empty value', () {
      var args = ArgsSimple.parse(['a', '--']);
      expect(args.arguments, equals(['a']));
      expect(args.options, equals({'': ''}));
    });

    test('an option always consumes the next argument as its value', () {
      var args = ArgsSimple.parse(['--a', '--b', '--c', '-flag', '--d', '-5']);
      expect(args.options, equals({'a': '--b', 'c': '-flag', 'd': '-5'}));
      expect(args.flags, isEmpty);
      expect(args.optionAsInt('d'), equals(-5));
    });

    test('a trailing option gets an empty value', () {
      var args = ArgsSimple.parse(['--port']);
      expect(args.options, equals({'port': ''}));
      expect(args.optionAsString('port'), equals(''));
      expect(args.optionAsInt('port', 8080), equals(8080));
      expect(args.optionAsBool('port', true), isTrue);
    });

    test('`--key=value` is not split: `=` is dropped from the key', () {
      var args = ArgsSimple.parse(['--port=81', 'x']);
      expect(args.options, equals({'port81': 'x'}));
      expect(args.option('port'), isNull);
    });

    test('`=` and `:` inside option values are preserved', () {
      var args = ArgsSimple.parse([
        '--url',
        'http://h:1/p?a=b&c=d',
        '--e',
        '=',
      ]);
      expect(args.optionAsString('url'), equals('http://h:1/p?a=b&c=d'));
      expect(args.optionAsString('e'), equals('='));
      expect(args.optionMatches('url', 'http://'), isTrue);
      expect(args.optionMatches('url', RegExp(r'a=b')), isTrue);
    });

    test('repeated option keeps every value, in order', () {
      var args = ArgsSimple.parse([
        '--h',
        'a',
        '--H',
        'b',
        '--h',
        'a',
        '--other',
        'o',
      ]);
      expect(
        args.options,
        equals({
          'h': ['a', 'b', 'a'],
          'other': 'o',
        }),
      );
      expect(args.optionAsList('h'), equals(['a', 'b', 'a']));
      expect(args.optionAsSet('h'), equals({'a', 'b'}));
      expect(args.optionAsString('other'), equals('o'));
    });

    test('option keys are looked up raw first, then normalized', () {
      var args = ArgsSimple();
      args.putOption('Sys-Config', '/etc');
      expect(args.options.keys, equals(['sysconfig']));
      expect(args.optionAsString('Sys-Config'), equals('/etc'));
      expect(args.optionAsString('SYS_CONFIG'), equals('/etc'));
      expect(args.optionAsString('sysconfig'), equals('/etc'));
      expect(args.optionAsString('sys'), isNull);
      expect(args.optionAsString('sys', 'd'), equals('d'));
    });

    test('typed option accessors with defaults', () {
      var args = ArgsSimple.parse([
        '--i',
        ' 42 ',
        '--d',
        '-1.5',
        '--b',
        'yes',
        '--l',
        'a, b ;c',
        '--m',
        'k1=v1; k2 : v2',
      ]);
      expect(args.optionAsInt('i'), equals(42));
      expect(args.optionAsDouble('d'), equals(-1.5));
      expect(args.optionAsBool('b'), isTrue);
      expect(args.optionAsList('l'), equals(['a', 'b', 'c']));
      expect(args.optionAsMap('m'), equals({'k1': 'v1', 'k2': 'v2'}));

      expect(args.optionAsInt('x', 1), equals(1));
      expect(args.optionAsDouble('x', 1.5), equals(1.5));
      expect(args.optionAsBool('x', false), isFalse);
      expect(args.optionAsList('x', const ['d']), equals(['d']));
      expect(args.optionAsSet('x', const {'d'}), equals({'d'}));
      expect(args.optionAsMap('x', const {'d': 1}), equals({'d': 1}));
      expect(args.optionMatches('x', 'a'), isFalse);
    });

    test('the default selects the parser of the generic accessor', () {
      var args = ArgsSimple.parse(['--n', '12', '--s', 'a;b']);
      expect(args.option('n', 0), equals(12));
      expect(args.option('n', 0.0), equals(12.0));
      expect(args.option('n', ''), equals('12'));
      expect(args.option('s', <dynamic>[]), equals(['a', 'b']));
      expect(args.option<int>('n'), equals(12));
      expect(args.option<Object>('n'), equals('12'));
    });
  });

  group('ArgsSimple.parse: flags', () {
    test('repeated and differently-cased flags collapse', () {
      var args = ArgsSimple.parse(['-v', '-V', '-v', '-Verbose']);
      expect(args.flags, equals({'v', 'verbose'}));
      expect(args.arguments, isEmpty);
    });

    test('flag lookup: raw, then normalized', () {
      var args = ArgsSimple.parse(['-dry-run']);
      expect(args.flags, equals({'dryrun'}));
      expect(args.flag('dry-run'), isTrue);
      expect(args.flag('DRY_RUN'), isTrue);
      expect(args.flag('dry'), isFalse);
      expect(args.flagOr('dry-run', false), isTrue);
      expect(args.flagOr('dry', false), isFalse);
      expect(args.flagOr('dry', null), isNull);
    });

    test('a lone `-` is a flag with an empty key', () {
      var args = ArgsSimple.parse(['-']);
      expect(args.flags, equals({''}));
      expect(args.flag(''), isTrue);
      expect(args.arguments, isEmpty);
    });

    test('flags starting with P or D are parsed as properties', () {
      // `-P`/`-D` is a property prefix, case-sensitively.
      var args = ArgsSimple.parse(['-Port', '-Debug', '-port', '-debug']);
      expect(args.properties, equals({'ort': '', 'ebug': ''}));
      expect(args.flags, equals({'port', 'debug'}));
    });
  });

  group('ArgsSimple.parse: negative numbers vs. flags', () {
    test('numeric values after `-` are arguments', () {
      var values = ['-1', '-0', '-1.5', '-.5', '-1e3', '-0x10', '-NaN'];
      var args = ArgsSimple.parse(values);
      expect(args.arguments, equals(values));
      expect(args.flags, isEmpty);

      expect(args.argumentAsInt(0), equals(-1));
      expect(args.argumentAsDouble(2), equals(-1.5));
      expect(args.argumentAsDouble(3), equals(-0.5));
      expect(args.argumentAsDouble(4), equals(-1000));
      expect(args.argumentAsInt(5), equals(-16));
      expect(args.argumentAsDouble(6)!.isNaN, isTrue);
    });

    test('non-numeric values after `-` are flags', () {
      var args = ArgsSimple.parse(['-1a', '-e5x', '--5', '7']);
      expect(args.flags, equals({'1a', 'e5x'}));
      expect(args.options, equals({'5': '7'}));
      expect(args.arguments, isEmpty);
    });
  });

  group('ArgsSimple.parse: properties', () {
    test('first `=` or `:` splits key and value', () {
      var args = ArgsSimple.parse([
        '-Pa=b=c',
        '-Db:c=d',
        '-Pe=',
        '-Pf',
        '-P=v',
        '-P',
      ]);
      expect(
        args.properties,
        equals({'a': 'b=c', 'b': 'c=d', 'e': '', 'f': '', '': ''}),
      );
    });

    test('`-P=v` gives the empty key a value', () {
      var args = ArgsSimple.parse(['-P=v']);
      expect(args.properties, equals({'': 'v'}));
    });

    test('a repeated property keeps the last value', () {
      var args = ArgsSimple.parse(['-Pk=1', '-DK=2']);
      expect(args.properties, equals({'k': '2'}));
      expect(args.propertyAsInt('k'), equals(2));
    });

    test('typed property accessors with defaults', () {
      var args = ArgsSimple.parse([
        '-Pi=7',
        '-Pd=2.5',
        '-Pb=off',
        '-Pl=x;y',
        '-Pm=a:1',
      ]);
      expect(args.propertyAsInt('i'), equals(7));
      expect(args.propertyAsDouble('d'), equals(2.5));
      // `off` is not a known bool literal: the default is returned.
      expect(args.propertyAsBool('b'), isNull);
      expect(args.propertyAsBool('b', true), isTrue);
      expect(args.propertyAsList('l'), equals(['x', 'y']));
      expect(args.propertyAsSet('l'), equals({'x', 'y'}));
      expect(args.propertyAsMap('m'), equals({'a': '1'}));
      expect(args.propertyMatches('m', 'a:'), isTrue);
      expect(args.propertyMatches('missing', 'a'), isFalse);
      expect(args.propertyAsString('missing', 'd'), equals('d'));
    });
  });

  group('ArgsSimple.parse: quoting and unicode', () {
    test('quotes and spaces are kept verbatim (no shell splitting)', () {
      var args = ArgsSimple.parse([
        '"quoted value"',
        "it's",
        'a b',
        '--msg',
        '  two  words  ',
        '-Pq="x y"',
      ]);
      expect(args.arguments, equals(['"quoted value"', "it's", 'a b']));
      expect(args.optionAsString('msg'), equals('  two  words  '));
      expect(args.propertyAsString('q'), equals('"x y"'));
    });

    test('unicode values are preserved; non a-z0-9 key chars are dropped', () {
      var args = ArgsSimple.parse([
        'José',
        '日本語',
        '--Ünïcode',
        'ünï 😀',
        '-Pclé=valeur',
        '-ñandú',
      ]);
      expect(args.arguments, equals(['José', '日本語']));
      expect(args.options, equals({'ncode': 'ünï 😀'}));
      expect(args.properties, equals({'cl': 'valeur'}));
      expect(args.flags, equals({'and'}));
    });
  });

  group('ArgsSimple: invalid values fall back to the default', () {
    // Regression: these used to throw a `TypeError` (`null as int`).
    var args = ArgsSimple.parse(['abc', '--port', 'abc', '-Pn=abc', '-Pb=?']);

    test('arguments', () {
      expect(args.argumentAsInt(0), isNull);
      expect(args.argumentAsInt(0, 1), equals(1));
      expect(args.argumentAsDouble(0, 1.5), equals(1.5));
      expect(args.argument<int>(0, 2), equals(2));
      expect(args.argument(0, DateTime(2020)), equals(DateTime(2020)));
    });

    test('options', () {
      expect(args.optionAsInt('port'), isNull);
      expect(args.optionAsInt('port', 8080), equals(8080));
      expect(args.optionAsDouble('port', 0.5), equals(0.5));
      expect(args.option<int>('port', 3), equals(3));
    });

    test('properties', () {
      expect(args.propertyAsInt('n'), isNull);
      expect(args.propertyAsInt('n', 9), equals(9));
      expect(args.propertyAsBool('b'), isNull);
      expect(args.propertyAsBool('b', false), isFalse);
    });

    test('a custom parser returning null also falls back', () {
      Object? never(Object? o) => null;
      expect(args.argument<String>(0, 'd', never), equals('d'));
      expect(args.option<String>('port', 'd', never), equals('d'));
      expect(args.property<String>('n', 'd', never), equals('d'));
      expect(args.option<String>('port', null, never), isNull);
    });

    test('valid values still win over the default', () {
      var a = ArgsSimple.parse(['5', '--port', '81', '-Pn=0']);
      expect(a.argumentAsInt(0, 1), equals(5));
      expect(a.optionAsInt('port', 8080), equals(81));
      expect(a.propertyAsInt('n', 9), equals(0));
      expect(a.propertyAsBool('n', true), isFalse);
    });
  });

  group('ArgsSimple: maps with a key without a value', () {
    test('dynamic map accessors keep the key with a null value', () {
      var args = ArgsSimple.parse(['a;b=1', '--m', 'a;b=1', '-Pm=a;b=1']);
      var expected = {'a': null, 'b': '1'};
      expect(args.argumentAsMap(0), equals(expected));
      expect(args.optionAsMap('m'), equals(expected));
      expect(args.propertyAsMap('m'), equals(expected));
    });
  });

  group('ArgsSimple arguments', () {
    test('typed accessors, out of range and defaults', () {
      var args = ArgsSimple.parse(['3', 'x;y', 'k=v', 'true']);
      expect(args.argument<int>(0), equals(3));
      expect(args.argument(0, 0.0), equals(3.0));
      expect(args.argument<String>(0), equals('3'));
      expect(args.argumentAsSet(1), equals({'x', 'y'}));
      expect(args.argumentAsMap(2), equals({'k': 'v'}));
      expect(args.argumentAsBool(3), isTrue);

      expect(args.argument<int>(9), isNull);
      expect(args.argument(9, 5), equals(5));
      expect(args.argumentAsDouble(9, 1.5), equals(1.5));
      expect(args.argumentAsSet(9, const {'d'}), equals({'d'}));
      expect(args.argumentMatches(9, 'x'), isFalse);
      expect(
        args.argument<int>(0, null, (o) => int.parse('$o') * 10),
        equals(30),
      );
    });

    test('addArgument appends after parsed arguments', () {
      var args = ArgsSimple.parse(['a'])..addArgument('b');
      expect(args.arguments, equals(['a', 'b']));
      expect(args.isNotEmpty, isTrue);
    });
  });

  group('ArgsSimple round-trip parse -> toList -> parse', () {
    void expectRoundTrip(List<String> input) {
      var (a, b) = roundTrip(input);
      expect(b.arguments, equals(a.arguments), reason: '$input');
      expect(b.flags, equals(a.flags), reason: '$input');
      expect(b.options, equals(a.options), reason: '$input');
      expect(b.properties, equals(a.properties), reason: '$input');
      // `toList` is a fixed point after one round-trip.
      expect(b.toList(), equals(a.toList()), reason: '$input');
    }

    test('mixed input', () {
      expectRoundTrip([
        'file.json',
        '-5',
        '-v',
        '--port',
        '81',
        '-Pa=b=c',
        'user',
        '-Dx:1',
      ]);
    });

    test('repeated options', () {
      expectRoundTrip(['--h', 'a', '--h', 'b', '--h', 'c', '--k', 'v']);
    });

    test('options whose values look like options or flags', () {
      expectRoundTrip(['--a', '--b', '--c', '-x', '--d', '']);
    });

    test('empty keys and trailing option', () {
      expectRoundTrip(['--', 'v', '-', '-P=w', '--last']);
    });

    test('quoting, spaces, `=` and unicode', () {
      expectRoundTrip([
        'a b',
        '"q"',
        '--url',
        'http://h/?a=b',
        '--ü',
        'José 😀',
        '-Pk=v w',
      ]);
    });

    test('empty input', () {
      expectRoundTrip(const []);
    });

    test('canonical order: arguments, flags, options, properties', () {
      var args = ArgsSimple.parse(['-Pp=1', '--o', 'v', '-f', 'arg']);
      expect(args.toList(), equals(['arg', '-f', '--o', 'v', '-Pp=1']));
    });

    test('values set programmatically are stringified', () {
      var args = ArgsSimple()
        ..putOption('n', 5)
        ..putProperty('b', true);
      expect(args.toList(), equals(['--n', '5', '-Pb=true']));
      var back = ArgsSimple.parse(args.toList());
      expect(back.options, equals({'n': '5'}));
      expect(back.optionAsInt('n'), equals(5));
      expect(back.propertyAsBool('b'), isTrue);
    });

    test('a programmatic argument starting with `-` becomes a flag', () {
      // Known limitation: `toList` does not escape arguments.
      var args = ArgsSimple()..addArgument('-x');
      var back = ArgsSimple.parse(args.toList());
      expect(back.arguments, isEmpty);
      expect(back.flags, equals({'x'}));
    });
  });

  group('ArgsSimple JSON', () {
    test('toJson exposes copies, flags as a Set', () {
      var args = ArgsSimple.parse(['a', '-f', '--o', 'v', '-Pp=1']);
      var json = args.toJson();
      expect(
        json,
        equals({
          'arguments': ['a'],
          'flags': {'f'},
          'options': {'o': 'v'},
          'properties': {'p': '1'},
        }),
      );
      expect(json['flags'], isA<Set>());

      (json['arguments'] as List).add('b');
      expect(args.arguments, equals(['a']));
    });

    test('fromJson(Map) reads options, null values become empty', () {
      var args = ArgsSimple.fromJson({'Port': 81, 'empty': null, 1: 'one'});
      expect(args.options, equals({'Port': 81, 'empty': '', '1': 'one'}));
      expect(args.optionAsInt('port'), isNull);
      expect(args.optionAsInt('Port'), equals(81));
      expect(args.arguments, isEmpty);
    });

    test('fromEncodedJson with a list parses like the command line', () {
      var args = ArgsSimple.fromEncodedJson('["a", "-v", "--n", 2, -3]');
      expect(args.arguments, equals(['a', '-3']));
      expect(args.flags, equals({'v'}));
      expect(args.optionAsInt('n'), equals(2));
    });

    test('fromEncodedJson rejects invalid JSON', () {
      expect(
        () => ArgsSimple.fromEncodedJson('{oops'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
