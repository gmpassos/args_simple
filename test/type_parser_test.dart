import 'package:args_simple/args_simple.dart';
import 'package:test/test.dart';

class _Point {
  final int x;
  final int y;

  _Point(this.x, this.y);
}

_Point? _parsePoint(Object? o) {
  var parts = '$o'.split('x');
  return _Point(int.parse(parts[0]), int.parse(parts[1]));
}

TypeElementParser? _pointResolver({Type? t, Object? obj, Type? type}) =>
    (obj is _Point || type == _Point || t == _Point) ? _parsePoint : null;

void main() {
  group('TypeParser.parserFor', () {
    test('by type argument', () {
      expect(TypeParser.parserFor<String>(), equals(TypeParser.parseString));
      expect(TypeParser.parserFor<int>(), equals(TypeParser.parseInt));
      expect(TypeParser.parserFor<double>(), equals(TypeParser.parseDouble));
      expect(TypeParser.parserFor<num>(), equals(TypeParser.parseNum));
      expect(TypeParser.parserFor<bool>(), equals(TypeParser.parseBool));
      expect(TypeParser.parserFor<BigInt>(), equals(TypeParser.parseBigInt));
      expect(
        TypeParser.parserFor<DateTime>(),
        equals(TypeParser.parseDateTime),
      );
      expect(TypeParser.parserFor<List>()!('a,b'), equals(['a', 'b']));
      expect(TypeParser.parserFor<Set>()!('a,b,a'), equals({'a', 'b'}));
      expect(TypeParser.parserFor<Map>()!('a=1'), equals({'a': '1'}));
    });

    test('by nullable type argument', () {
      // Regression: no parser was found for nullable types.
      expect(TypeParser.parserFor<String?>(), equals(TypeParser.parseString));
      expect(TypeParser.parserFor<int?>(), equals(TypeParser.parseInt));
      expect(TypeParser.parserFor<double?>(), equals(TypeParser.parseDouble));
      expect(TypeParser.parserFor<num?>(), equals(TypeParser.parseNum));
      expect(TypeParser.parserFor<bool?>(), equals(TypeParser.parseBool));
      expect(TypeParser.parserFor<BigInt?>(), equals(TypeParser.parseBigInt));
      expect(
        TypeParser.parserFor<DateTime?>(),
        equals(TypeParser.parseDateTime),
      );
      expect(TypeParser.parserFor<List?>()!('a,b'), equals(['a', 'b']));
      expect(TypeParser.parserFor<Set?>()!('a,b,a'), equals({'a', 'b'}));
      expect(TypeParser.parserFor<Map?>()!('a=1'), equals({'a': '1'}));
      expect(TypeParser.parserFor<_Point?>(), isNull);
    });

    test('nullable type arguments in the generic accessors', () {
      var args = ArgsSimple.parse(['7', '--n', '12', '-Pb=yes']);
      expect(args.argument<int?>(0), equals(7));
      expect(args.option<int?>('n'), equals(12));
      expect(args.option<double?>('n'), equals(12.0));
      expect(args.property<bool?>('b'), isTrue);
      expect(args.option<int?>('missing'), isNull);
    });

    test('by `type` parameter', () {
      expect(TypeParser.parserFor(type: int), equals(TypeParser.parseInt));
      expect(TypeParser.parserFor(type: bool), equals(TypeParser.parseBool));
    });

    test('by object', () {
      expect(TypeParser.parserFor(obj: 'x'), equals(TypeParser.parseString));
      expect(TypeParser.parserFor(obj: 1), equals(TypeParser.parseInt));
      expect(TypeParser.parserFor(obj: 1.5), equals(TypeParser.parseDouble));
      expect(TypeParser.parserFor(obj: true), equals(TypeParser.parseBool));
      expect(
        TypeParser.parserFor(obj: BigInt.one),
        equals(TypeParser.parseBigInt),
      );
      expect(
        TypeParser.parserFor(obj: DateTime(2020)),
        equals(TypeParser.parseDateTime),
      );
      expect(TypeParser.parserFor(obj: [1])!('a;b'), equals(['a', 'b']));
      expect(TypeParser.parserFor(obj: {1})!('a;a'), equals({'a'}));
      expect(TypeParser.parserFor(obj: {1: 2})!('k:v'), equals({'k': 'v'}));
    });

    test('unknown type', () {
      expect(TypeParser.parserFor<_Point>(), isNull);
      expect(TypeParser.parserFor(obj: _Point(1, 2)), isNull);
    });

    test('registered resolver', () {
      TypeParser.registerParserResolver(_pointResolver);
      try {
        var parser = TypeParser.parserFor<_Point>();
        expect(parser, isNotNull);
        var p = parser!('3x4') as _Point;
        expect([p.x, p.y], equals([3, 4]));

        expect(TypeParser.parserFor(obj: _Point(0, 0)), isNotNull);
      } finally {
        expect(TypeParser.unregisterParserResolver(_pointResolver), isTrue);
      }
      expect(TypeParser.parserFor<_Point>(), isNull);
      expect(TypeParser.unregisterParserResolver(_pointResolver), isFalse);
    });
  });

  group('TypeParser.parseList', () {
    test('from String', () {
      expect(TypeParser.parseList('a, b ;c'), equals(['a', 'b', 'c']));
      expect(TypeParser.parseList('a'), equals(['a']));
    });

    test('null and empty', () {
      expect(TypeParser.parseList(null), isNull);
      expect(TypeParser.parseList(null, def: [1]), equals([1]));
      expect(TypeParser.parseList('  ', def: ['x']), equals(['x']));
    });

    test('from List and Iterable', () {
      var l = [1, 2];
      expect(TypeParser.parseList<int>(l), same(l));
      expect(TypeParser.parseList({1, 2}), equals([1, 2]));
    });

    test('typed, with implicit element parser', () {
      expect(TypeParser.parseList<int>('1, 2,3'), equals([1, 2, 3]));
      expect(TypeParser.parseList<int>('1,zz,3'), equals([1, 3]));
      expect(TypeParser.parseList<int>(['1', 2, 3.0]), equals([1, 2, 3]));
    });

    test('with element parser', () {
      expect(
        TypeParser.parseList<int>('1,2', elementParser: TypeParser.parseInt),
        allOf(equals([1, 2]), isA<List<int>>()),
      );
      expect(
        TypeParser.parseList<bool>(
          'yes,no,zz',
          elementParser: TypeParser.parseBool,
        ),
        equals([true, false]),
      );
    });
  });

  group('TypeParser.parseSet', () {
    test('basic', () {
      expect(TypeParser.parseSet('a,b,a'), equals({'a', 'b'}));
      expect(TypeParser.parseSet<int>('1;2;2'), equals({1, 2}));
      expect(TypeParser.parseSet(null, def: {'d'}), equals({'d'}));
      expect(TypeParser.parseSet(''), isNull);
    });
  });

  group('TypeParser.parseMap', () {
    test('from String', () {
      expect(
        TypeParser.parseMap('a=1; b:2&c=3'),
        equals({'a': '1', 'b': '2', 'c': '3'}),
      );
      expect(
        TypeParser.parseMap<String, int>('a=1;b=2'),
        equals({'a': 1, 'b': 2}),
      );
    });

    test('spaces around the key/value delimiter', () {
      expect(
        TypeParser.parseMap('a = 1; b : two'),
        equals({'a': '1', 'b': 'two'}),
      );
    });

    test('key without value', () {
      expect(TypeParser.parseMap('a;b=1'), equals({'a': null, 'b': '1'}));
    });

    test('key without value and a non-nullable value type', () {
      // Regression: used to throw a `TypeError` (`null as String`).
      expect(TypeParser.parseMap<String, String>('a;b=1'), equals({'b': '1'}));
      expect(TypeParser.parseMap<String, int>('a;b=1;c'), equals({'b': 1}));
      expect(TypeParser.parseMap<String, String>('a'), isEmpty);
      // A nullable value type keeps the key, with a `null` value.
      expect(
        TypeParser.parseMap<String, String?>('a;b=1'),
        equals({'a': null, 'b': '1'}),
      );
    });

    test('unparseable value with a non-nullable value type', () {
      // Regression: used to throw a `TypeError` (`null as int`). The entry is
      // now skipped, like a key without a value.
      expect(TypeParser.parseMap<String, int>('a=x'), isEmpty);
      expect(TypeParser.parseMap<String, int>('a=x;b=2;c=?'), equals({'b': 2}));
      expect(
        TypeParser.parseMap<String, int>({'a': 'x', 'b': '2', 'c': null}),
        equals({'b': 2}),
      );
      expect(
        TypeParser.parseMap<String, int>([
          ['a', 'x'],
          ['b', '2'],
        ]),
        equals({'b': 2}),
      );
      expect(
        TypeParser.parseMap<int, String>(
          '1=a;x=b',
          keyParser: TypeParser.parseInt,
        ),
        equals({1: 'a'}),
      );
      // A nullable value type keeps the key, with a `null` value.
      expect(
        TypeParser.parseMap<String, int?>('a=x;b=2'),
        equals({'a': null, 'b': 2}),
      );
      // A type without a parser: values of another type are skipped.
      expect(
        TypeParser.parseMap<String, List<String>>({
          'a': 'x',
          'b': ['y'],
        }),
        equals({
          'b': ['y'],
        }),
      );
      // An explicit value parser decides how to handle it.
      expect(
        TypeParser.parseMap<String, int>(
          'a=x;b=2',
          valueParser: (v) => TypeParser.parseInt(v, -1),
        ),
        equals({'a': -1, 'b': 2}),
      );
    });

    test('trims the whole value and splits on `;` and `&`', () {
      expect(
        TypeParser.parseMap('  a=1 & b=2 ;c=3  '),
        equals({'a': '1', 'b': '2', 'c': '3'}),
      );
      // Only the first delimiter separates key and value.
      expect(TypeParser.parseMap('u=a:b=c'), equals({'u': 'a:b=c'}));
    });

    test('null and empty', () {
      expect(TypeParser.parseMap(null), isNull);
      expect(TypeParser.parseMap(null, def: {'d': 1}), equals({'d': 1}));
      expect(TypeParser.parseMap(' ', def: {'d': 1}), equals({'d': 1}));
    });

    test('from Map', () {
      var m = <String, int>{'a': 1};
      expect(TypeParser.parseMap<String, int>(m), same(m));
      expect(
        TypeParser.parseMap<String, int>({'a': '1', 'b': 2.0}),
        equals({'a': 1, 'b': 2}),
      );
    });

    test('from Iterable of pairs', () {
      expect(
        TypeParser.parseMap<String, int>([
          ['a', '1'],
          'b=2',
          const MapEntry('c', 3),
        ]),
        equals({'a': 1, 'b': 2, 'c': 3}),
      );
    });

    test('with key and value parsers', () {
      expect(
        TypeParser.parseMap<int, bool>(
          '1=yes;2=no',
          keyParser: TypeParser.parseInt,
          valueParser: TypeParser.parseBool,
        ),
        equals({1: true, 2: false}),
      );
    });
  });

  group('TypeParser.parseMapEntry', () {
    test('basic', () {
      var e = TypeParser.parseMapEntry<String, int>('a=1')!;
      expect([e.key, e.value], equals(['a', 1]));

      e = TypeParser.parseMapEntry<String, int>(const MapEntry('b', '2'))!;
      expect([e.key, e.value], equals(['b', 2]));

      e = TypeParser.parseMapEntry<String, int>(['c', 3])!;
      expect([e.key, e.value], equals(['c', 3]));

      var same = const MapEntry('x', 1);
      expect(TypeParser.parseMapEntry<String, int>(same), equals(same));
    });

    test('null and empty', () {
      var def = const MapEntry('d', 0);
      expect(TypeParser.parseMapEntry(null), isNull);
      expect(TypeParser.parseMapEntry(null, def: def), equals(def));
      expect(TypeParser.parseMapEntry('', def: def), equals(def));
    });

    test('key without value', () {
      var e = TypeParser.parseMapEntry<String, String?>(' a ')!;
      expect([e.key, e.value], equals(['a', null]));

      var def = const MapEntry('d', 'v');
      expect(TypeParser.parseMapEntry<String, String>('a'), isNull);
      expect(
        TypeParser.parseMapEntry<String, String>('a', def: def),
        equals(def),
      );
    });

    test('unparseable key or value returns def', () {
      // Regression: used to throw a `TypeError` (`null as int`).
      var def = const MapEntry('d', 0);
      expect(TypeParser.parseMapEntry<String, int>('a=x'), isNull);
      expect(
        TypeParser.parseMapEntry<String, int>('a=x', def: def),
        equals(def),
      );
      expect(
        TypeParser.parseMapEntry<String, int>(const MapEntry('a', 'x')),
        isNull,
      );
      expect(TypeParser.parseMapEntry<String, int>(['a', 'x']), isNull);
      expect(
        TypeParser.parseMapEntry<int, String>(
          'x=a',
          def: const MapEntry(0, 'd'),
          keyParser: TypeParser.parseInt,
        ),
        equals(const MapEntry(0, 'd')),
      );
      var e = TypeParser.parseMapEntry<String, int?>('a=x')!;
      expect([e.key, e.value], equals(['a', null]));
    });

    test('from a short Iterable', () {
      var def = const MapEntry('d', 0);
      expect(TypeParser.parseMapEntry<String, int>([], def: def), equals(def));
      expect(
        TypeParser.parseMapEntry<String, int>(['a'], def: def),
        equals(def),
      );
      var e = TypeParser.parseMapEntry<String, int?>(['a'])!;
      expect([e.key, e.value], equals(['a', null]));
    });

    test('types without a parser are cast as-is', () {
      var e = TypeParser.parseMapEntry<Object, Object>('k=1')!;
      expect([e.key, e.value], equals(['k', '1']));
      var p = TypeParser.parseMap<Object, Object>({1: 2})!;
      expect(p, equals({1: 2}));
    });
  });

  group('TypeParser scalars', () {
    test('parseString', () {
      expect(TypeParser.parseString('a'), equals('a'));
      expect(TypeParser.parseString(12), equals('12'));
      expect(TypeParser.parseString(null), isNull);
      expect(TypeParser.parseString(null, 'd'), equals('d'));
    });

    test('parseInt', () {
      expect(TypeParser.parseInt(5), equals(5));
      expect(TypeParser.parseInt(3.7), equals(3));
      expect(TypeParser.parseInt(' 42 '), equals(42));
      expect(TypeParser.parseInt('3.7'), equals(3));
      expect(TypeParser.parseInt(r'$1000'), equals(1000));
      expect(TypeParser.parseInt(DateTime.utc(1970, 1, 1, 0, 0, 1)), 1000);
      expect(TypeParser.parseInt(null), isNull);
      expect(TypeParser.parseInt(null, 7), equals(7));
      expect(TypeParser.parseInt('', 7), equals(7));
      expect(TypeParser.parseInt('zz', 7), equals(7));
      // Non-String objects are parsed from their `toString`.
      expect(TypeParser.parseInt(StringBuffer(' 42 ')), equals(42));
      expect(TypeParser.parseDouble(StringBuffer('1.5')), equals(1.5));
    });

    test('parseDouble', () {
      expect(TypeParser.parseDouble(1.5), equals(1.5));
      expect(TypeParser.parseDouble(2), allOf(equals(2.0), isA<double>()));
      expect(TypeParser.parseDouble(' 2.25 '), equals(2.25));
      expect(TypeParser.parseDouble(DateTime.utc(1970, 1, 1, 0, 0, 2)), 2000);
      expect(TypeParser.parseDouble(null, 1.0), equals(1.0));
      expect(TypeParser.parseDouble('zz', 1.0), equals(1.0));
    });

    test('parseNum', () {
      expect(TypeParser.parseNum(3), equals(3));
      expect(TypeParser.parseNum('10'), allOf(equals(10), isA<int>()));
      expect(TypeParser.parseNum('1.5'), equals(1.5));
      expect(TypeParser.parseNum(DateTime.utc(1970, 1, 1, 0, 0, 3)), 3000);
      expect(TypeParser.parseNum(null, 4), equals(4));
      expect(TypeParser.parseNum('zz', 4), equals(4));
    });

    test('parseBigInt', () {
      expect(
        TypeParser.parseBigInt('123456789012345678901234567890'),
        equals(BigInt.parse('123456789012345678901234567890')),
      );
      expect(TypeParser.parseBigInt(BigInt.two), equals(BigInt.two));
      expect(TypeParser.parseBigInt(5), equals(BigInt.from(5)));
      expect(TypeParser.parseBigInt('#12'), equals(BigInt.from(12)));
      expect(
        TypeParser.parseBigInt(DateTime.utc(1970, 1, 1, 0, 0, 1)),
        equals(BigInt.from(1000)),
      );
      expect(TypeParser.parseBigInt(null, BigInt.one), equals(BigInt.one));
      expect(TypeParser.parseBigInt(' ', BigInt.one), equals(BigInt.one));
      expect(TypeParser.parseBigInt('zz', BigInt.one), equals(BigInt.one));
    });

    test('parseBool', () {
      for (var t in ['true', 'T', 'yes', 'y', '1', '+', 'OK']) {
        expect(TypeParser.parseBool(t), isTrue, reason: t);
      }
      for (var f in [
        'false',
        'F',
        'no',
        'n',
        '0',
        '-1',
        '-',
        'fail',
        'error',
        'err',
      ]) {
        expect(TypeParser.parseBool(f), isFalse, reason: f);
      }
      expect(TypeParser.parseBool(true), isTrue);
      expect(TypeParser.parseBool(1), isTrue);
      expect(TypeParser.parseBool(0), isFalse);
      expect(TypeParser.parseBool('5'), isTrue);
      expect(TypeParser.parseBool('-5'), isFalse);
      expect(TypeParser.parseBool(null), isNull);
      expect(TypeParser.parseBool(null, true), isTrue);
      expect(TypeParser.parseBool('', true), isTrue);
      expect(TypeParser.parseBool('null', false), isFalse);
      expect(TypeParser.parseBool('empty', true), isTrue);
      expect(TypeParser.parseBool('zz', true), isTrue);
    });

    test('parseDateTime', () {
      var d = DateTime.utc(2020, 1, 2, 3, 4, 5);
      expect(TypeParser.parseDateTime(d), same(d));
      expect(TypeParser.parseDateTime('2020-01-02T03:04:05Z'), equals(d));
      expect(
        TypeParser.parseDateTime(d.millisecondsSinceEpoch)!.toUtc(),
        equals(d),
      );
      expect(
        TypeParser.parseDateTime('${d.millisecondsSinceEpoch}')!.toUtc(),
        equals(d),
      );
      expect(TypeParser.parseDateTime(null), isNull);
      expect(TypeParser.parseDateTime(null, d), equals(d));
      expect(TypeParser.parseDateTime('not a date', d), equals(d));
    });
  });
}
