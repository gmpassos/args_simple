import 'package:collection/collection.dart';

typedef TypeElementParser<T> = T? Function(Object? o);

typedef TypeParserResolver = TypeElementParser? Function(
    {Type? t, Object? obj, Type? type});

/// Lenient parsers for basic Dart types.
class TypeParser {
  static final Set<TypeParserResolver> _parsersResolvers =
      <TypeParserResolver>{};

  static void registerParserResolver(TypeParserResolver parserResolver) =>
      _parsersResolvers.add(parserResolver);

  static bool unregisterParserResolver(TypeParserResolver parserResolver) =>
      _parsersResolvers.remove(parserResolver);

  /// Returns the parser for the desired type, defined by [T], [obj] or [type].
  static TypeElementParser? parserFor<T>({Object? obj, Type? type}) {
    if (obj != null) {
      if (obj is String) {
        return parseString;
      } else if (obj is Map) {
        return parseMap;
      } else if (obj is Set) {
        return parseSet;
      } else if (obj is List || obj is Iterable) {
        return parseList;
      } else if (obj is int) {
        return parseInt;
      } else if (obj is double) {
        return parseDouble;
      } else if (obj is num) {
        return parseNum;
      } else if (obj is bool) {
        return parseBool;
      } else if (obj is BigInt) {
        return parseBigInt;
      } else if (obj is DateTime) {
        return parseDateTime;
      }
    }

    type ??= obj?.runtimeType ?? T;

    if (type == String) {
      return parseString;
    } else if (type == Map) {
      return parseMap;
    } else if (type == Set) {
      return parseSet;
    } else if (type == List) {
      return parseList;
    } else if (type == int) {
      return parseInt;
    } else if (type == double) {
      return parseDouble;
    } else if (type == num) {
      return parseNum;
    } else if (type == bool) {
      return parseBool;
    } else if (type == BigInt) {
      return parseBigInt;
    } else if (type == DateTime) {
      return parseDateTime;
    }

    for (var r in _parsersResolvers) {
      var parser = r(t: T, type: type, obj: obj);
      if (parser != null) return parser;
    }

    return null;
  }

  static final RegExp _regexpListDelimiter = RegExp(r'\s*[,;]\s*');

  /// Tries to parse a [List].
  /// - Returns [def] if [value] is `null` or an empty [String].
  /// - [elementParser] is an optional parser for the elements of the parsed [List].
  static List<T>? parseList<T>(Object? value,
      {List<T>? def, TypeElementParser<T>? elementParser}) {
    if (value == null) return def;

    var l = _parseListImpl(value);
    if (l == null) return def;

    if (elementParser != null) {
      l = l.map(elementParser).toList();
    }

    if (l is List<T>) {
      return l;
    } else if (elementParser != null) {
      l = l.whereType<T>().toList();
    } else {
      var parser = parserFor<T>();
      if (parser != null) {
        l = l.map(parser).toList();
      }
    }

    if (l is List<T>) {
      return l;
    } else {
      return l.whereType<T>().toList();
    }
  }

  static List? _parseListImpl<T>(Object value) {
    if (value is List) {
      return value;
    } else if (value is Iterable) {
      return value.toList();
    } else {
      var s = '$value'.trim();
      if (s.isEmpty) return null;
      var l = s.split(_regexpListDelimiter);
      return l;
    }
  }

  /// Tries to parse a [Set].
  ///
  /// See [parseList].
  static Set<T>? parseSet<T>(Object? value,
      {Set<T>? def, TypeElementParser<T>? elementParser}) {
    var l = parseList<T>(value, elementParser: elementParser);
    return l?.toSet() ?? def;
  }

  static final RegExp _regexpPairDelimiter = RegExp(r'\s*[;&]\s*');
  static final RegExp _regexpKeyValueDelimiter = RegExp(r'\s*[:=]\s*');

  /// Tries to parse a [Map].
  /// - Returns [def] if [value] is `null` or an empty [String].
  static Map<K, V>? parseMap<K, V>(Object? value,
      {Map<K, V>? def,
      TypeElementParser<K>? keyParser,
      TypeElementParser<V>? valueParser}) {
    if (value == null) return def;

    if (value is Map<K, V>) {
      return value;
    }

    keyParser ??= parserFor<K>() as TypeElementParser<K>?;
    keyParser ??= (k) => k as K;

    valueParser ??= parserFor<V>() as TypeElementParser<V>?;
    valueParser ??= (v) => v as V;

    if (value is Map) {
      return value
          .map((k, v) => MapEntry(keyParser!(k) as K, valueParser!(v) as V));
    } else if (value is Iterable) {
      return Map.fromEntries(value
          .map((e) => parseMapEntry<K, V>(e,
              keyParser: keyParser, valueParser: valueParser))
          .whereNotNull());
    } else {
      var s = '$value'.trim();
      if (s.isEmpty) return def;

      var pairs = s.split(_regexpPairDelimiter);
      return Map.fromEntries(pairs
          .map((e) => parseMapEntry<K, V>(e,
              keyParser: keyParser, valueParser: valueParser))
          .whereNotNull());
    }
  }

  /// Tries to parse a [MapEntry].
  /// - Returns [def] if [value] is `null` or an empty [String].
  static MapEntry<K, V>? parseMapEntry<K, V>(Object? value,
      {MapEntry<K, V>? def,
      TypeElementParser<K>? keyParser,
      TypeElementParser<V>? valueParser}) {
    if (value == null) return def;

    if (value is MapEntry<K, V>) {
      return value;
    }

    keyParser ??= parserFor<K>() as TypeElementParser<K>?;
    keyParser ??= (k) => k as K;

    valueParser ??= parserFor<V>() as TypeElementParser<V>?;
    valueParser ??= (v) => v as V;

    if (value is MapEntry) {
      return MapEntry(keyParser(value.key) as K, valueParser(value.value) as V);
    } else if (value is Iterable) {
      var k = value.elementAt(0);
      var v = value.elementAt(1);
      return MapEntry(keyParser(k) as K, valueParser(v) as V);
    } else {
      var s = '$value'.trim();
      if (s.isEmpty) return def;

      var idx = s.indexOf(_regexpKeyValueDelimiter);
      if (idx >= 0) {
        var k = s.substring(0, idx);
        var v = s.substring(idx + 1);
        return MapEntry(keyParser(k) as K, valueParser(v) as V);
      }
      return MapEntry(keyParser(s) as K, null as V);
    }
  }

  /// Tries to parse a [String].
  /// - Returns [def] if [value] is `null`.
  static String? parseString(Object? value, [String? def]) {
    if (value == null) return def;

    if (value is String) {
      return value;
    } else {
      return '$value';
    }
  }

  static final RegExp _regExpNotNumber = RegExp(r'[^0-9\.\+\-eENna]');

  /// Tries to parse an [int].
  /// - Returns [def] if [value] is invalid.
  static int? parseInt(Object? value, [int? def]) {
    if (value == null) return def;

    if (value is int) {
      return value;
    } else if (value is num) {
      return value.toInt();
    } else if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    } else {
      var n = _parseNumString(value);
      return n?.toInt() ?? def;
    }
  }

  static num? _parseNumString(Object value) {
    var s = _valueAsString(value);
    if (s.isEmpty) {
      return null;
    }

    var n = num.tryParse(s);
    if (n == null) {
      s = s.replaceAll(_regExpNotNumber, '');
      n = num.tryParse(s);
    }

    return n;
  }

  static String _valueAsString(Object value) {
    String s;
    if (value is String) {
      s = value.trim();
    } else {
      s = '$value'.trim();
    }
    return s;
  }

  /// Tries to parse a [double].
  /// - Returns [def] if [value] is invalid.
  static double? parseDouble(Object? value, [double? def]) {
    if (value == null) return def;

    if (value is double) {
      return value;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is DateTime) {
      return value.millisecondsSinceEpoch.toDouble();
    } else {
      var n = _parseNumString(value);
      return n?.toDouble() ?? def;
    }
  }

  /// Tries to parse a [num].
  /// - Returns [def] if [value] is invalid.
  static num? parseNum(Object? value, [num? def]) {
    if (value == null) return def;

    if (value is num) {
      return value;
    } else if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    } else {
      var n = _parseNumString(value);
      return n ?? def;
    }
  }

  /// Tries to parse a [BigInt].
  /// - Returns [def] if [value] is invalid.
  static BigInt? parseBigInt(Object? value, [BigInt? def]) {
    if (value == null) return def;

    if (value is BigInt) {
      return value;
    } else if (value is num) {
      return BigInt.from(value);
    } else if (value is DateTime) {
      return BigInt.from(value.millisecondsSinceEpoch);
    } else {
      var s = _valueAsString(value);
      if (s.isEmpty) {
        return def;
      }

      var n = BigInt.tryParse(s);
      if (n == null) {
        s = s.replaceAll(_regExpNotNumber, '');
        n = BigInt.tryParse(s);
      }

      return n ?? def;
    }
  }

  /// Tries to parse a [bool].
  /// - Returns [def] if [value] is invalid.
  static bool? parseBool(Object? value, [bool? def]) {
    if (value == null) return def;

    if (value is bool) {
      return value;
    } else if (value is num) {
      return value > 0;
    } else {
      var s = _valueAsString(value).toLowerCase();
      if (s.isEmpty || s == 'null' || s == 'empty') return def;

      if (s == 'true' ||
          s == 't' ||
          s == 'yes' ||
          s == 'y' ||
          s == '1' ||
          s == '+' ||
          s == 'ok') {
        return true;
      }

      if (s == 'false' ||
          s == 'f' ||
          s == 'no' ||
          s == 'n' ||
          s == '0' ||
          s == '-1' ||
          s == '-' ||
          s == 'fail' ||
          s == 'error' ||
          s == 'err') {
        return false;
      }

      var n = _parseNumString(value);
      if (n != null) {
        return n > 0;
      }

      return def;
    }
  }

  /// Tries to parse a [DateTime].
  /// - Returns [def] if [value] is invalid.
  static DateTime? parseDateTime(Object? value, [DateTime? def]) {
    if (value == null) return def;

    if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      var s = '$value'.trim();
      var ms = int.tryParse(s);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      return DateTime.tryParse(s) ?? def;
    }
  }
}
