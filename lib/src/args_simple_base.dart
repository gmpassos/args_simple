import 'dart:collection';
import 'dart:convert' as dart_convert;

import 'package:args_simple/src/type_parser.dart';

class ArgsSimple {
  final List<String> _arguments = <String>[];

  List<String> get arguments => UnmodifiableListView<String>(_arguments);

  final Map<String, Object> _options = <String, Object>{};

  Map<String, Object> get options =>
      UnmodifiableMapView<String, Object>(_options);

  final Set<String> _flags = {};

  Set<String> get flags => UnmodifiableSetView<String>(_flags);

  final Map<String, Object> _properties = <String, Object>{};

  Map<String, Object> get properties =>
      UnmodifiableMapView<String, Object>(_properties);

  ArgsSimple();

  factory ArgsSimple.fromEncodedJson(String encodedJson) {
    var json = dart_convert.json.decode(encodedJson);
    return ArgsSimple.fromJson(json);
  }

  /// Creates an [ArgsSimple] from a JSON value:
  /// - A [List]: its elements (as [String]s) are parsed like a command line
  ///   (see [ArgsSimple.parse]).
  /// - A [Map] in the [toJson] format: a non-empty [Map] whose keys are only
  ///   `arguments` (a [List]), `flags` (a [List]/[Set]), `options` and
  ///   `properties` (both [Map]s). `toJson -> fromJson` round-trips.
  /// - Any other [Map]: its entries are the options (a `null` value becomes
  ///   an empty [String]; the keys are kept as given).
  /// - Anything else: a single argument (`'$json'`).
  factory ArgsSimple.fromJson(Object json) {
    if (json is List<String>) {
      return ArgsSimple.parse(json);
    } else if (json is List) {
      return ArgsSimple.parse(json.map((e) => '$e').toList());
    }

    var args = ArgsSimple();

    if (json is Map) {
      if (_isJsonSections(json)) {
        args._loadJsonSections(json);
      } else {
        args._options.addAll(
          json.map((key, value) => MapEntry(key.toString(), value ?? '')),
        );
      }
    } else {
      var s = '$json';
      args._arguments.add(s);
    }

    return args;
  }

  /// Whether [json] is in the [toJson] format.
  static bool _isJsonSections(Map json) {
    if (json.isEmpty) return false;
    for (var e in json.entries) {
      var v = e.value;
      var ok = switch (e.key) {
        'arguments' => v is List,
        'flags' => v is List || v is Set,
        'options' || 'properties' => v is Map,
        _ => false,
      };
      if (!ok) return false;
    }
    return true;
  }

  void _loadJsonSections(Map json) {
    for (var a in json['arguments'] as List? ?? const []) {
      _arguments.add('${a ?? ''}');
    }

    for (var f in json['flags'] as Iterable? ?? const []) {
      _flags.add(normalizeKey('$f'));
    }

    Object jsonValue(Object? v) =>
        v is List ? v.map((e) => e ?? '').toList() : v ?? '';

    var options = json['options'] as Map? ?? const {};
    for (var e in options.entries) {
      _options[normalizeKey('${e.key}')] = jsonValue(e.value);
    }

    var properties = json['properties'] as Map? ?? const {};
    for (var e in properties.entries) {
      _properties[normalizeKey('${e.key}')] = jsonValue(e.value);
    }
  }

  /// The delimiters between the key and the value of a property
  /// (`-Dkey=value` or `-Dkey:value`).
  static final RegExp _propertyDelimiter = RegExp(r'[=:]');

  /// Parses command-line [args]:
  ///
  /// - `--`: ends option parsing. Every following element is an argument,
  ///   even if it starts with `-`.
  /// - `--key=value`: the option `key` with `value` (split on the first `=`;
  ///   the value may be empty or contain `=`).
  /// - `--key value`: the option `key` with `value`. The next element is
  ///   always consumed as the value (even if it starts with `-`, or is `--`);
  ///   a trailing `--key` gets an empty value. An option given more than once
  ///   is stored as a [List] of its values.
  /// - `-Dkey=value` / `-Pkey=value` (case-sensitive `D`/`P`, Java-style): the
  ///   property `key` with `value` (split on the first `=` or `:`). Without a
  ///   `=`/`:` (`-Debug`, `-Port`) it is a flag.
  /// - `-number` (`-1`, `-1.5`, `-1e3`): an argument (a negative number).
  /// - `-name`: the flag `name`. There is no `-name=value` form: `=` is not a
  ///   key character, so `-name=1` is the flag `name1`.
  /// - Anything else: an argument.
  ///
  /// Keys are normalized with [normalizeKey].
  ArgsSimple.parse([List<String> args = const <String>[]]) {
    final length = args.length;

    for (var i = 0; i < length;) {
      var a = args[i];

      if (a == '--') {
        _arguments.addAll(args.sublist(i + 1));
        break;
      } else if (a.startsWith('--')) {
        String k, v;
        var idx = a.indexOf('=');
        if (idx >= 0) {
          k = normalizeKey(a.substring(2, idx));
          v = a.substring(idx + 1);
          ++i;
        } else {
          k = normalizeKey(a.substring(2));
          v = i < length - 1 ? args[i + 1] : '';
          i += 2;
        }
        _addOption(k, v);
      } else if ((a.startsWith('-P') || a.startsWith('-D')) &&
          a.contains(_propertyDelimiter)) {
        var idx = a.indexOf(_propertyDelimiter);
        var k = normalizeKey(a.substring(2, idx));
        var v = a.substring(idx + 1);
        _properties[k] = v;
        ++i;
      } else if (_isNegativeNumber(a)) {
        _arguments.add(a);
        ++i;
      } else if (a.startsWith('-')) {
        _flags.add(normalizeKey(a.substring(1)));
        ++i;
      } else {
        _arguments.add(a);
        ++i;
      }
    }
  }

  void _addOption(String k, String v) {
    var prev = _options[k];
    if (prev != null) {
      if (prev is List) {
        prev.add(v);
      } else {
        _options[k] = [prev, v];
      }
    } else {
      _options[k] = v;
    }
  }

  /// Whether [a] is `-` followed by a number (parsed as an argument).
  static bool _isNegativeNumber(String a) =>
      a.startsWith('-') &&
      !a.startsWith('--') &&
      num.tryParse(a.substring(1)) != null;

  /// Whether the argument [a] would not be parsed back as an argument by
  /// [ArgsSimple.parse] (it needs to come after `--` in [toList]).
  static bool _needsEndOfOptions(String a) =>
      a.startsWith('-') && !_isNegativeNumber(a);

  bool get isEmpty =>
      _arguments.isEmpty &&
      _flags.isEmpty &&
      _options.isEmpty &&
      _properties.isEmpty;

  bool get isNotEmpty => !isEmpty;

  void addArgument(String value) => _arguments.add(value);

  T? argument<T>(int index, [T? def, TypeElementParser? parser]) {
    if (index >= _arguments.length) return def;
    var value = _arguments[index];

    parser ??= TypeParser.parserFor<T>(obj: def);
    if (parser != null) {
      // A parser returns `null` for an invalid value: fall back to [def].
      return parser(value) as T? ?? def;
    } else {
      return value as T;
    }
  }

  bool argumentMatches(int index, Pattern pattern) {
    var val = argumentAsString(index);
    if (val == null) return false;

    return _matches(pattern, val);
  }

  int? argumentAsInt(int index, [int? def]) =>
      argument<int>(index, def, TypeParser.parseInt);

  double? argumentAsDouble(int index, [double? def]) =>
      argument<double>(index, def, TypeParser.parseDouble);

  String? argumentAsString(int index, [String? def]) =>
      argument<String>(index, def, (s) => s);

  bool? argumentAsBool(int index, [bool? def]) =>
      argument<bool>(index, def, TypeParser.parseBool);

  List? argumentAsList(int index, [List? def]) =>
      argument<List>(index, def, TypeParser.parseList);

  Set? argumentAsSet(int index, [Set? def]) =>
      argument<Set>(index, def, TypeParser.parseSet);

  Map? argumentAsMap(int index, [Map? def]) =>
      argument<Map>(index, def, TypeParser.parseMap);

  void putOption(String key, Object value) =>
      _options[normalizeKey(key)] = value;

  T? option<T>(String key, [T? def, TypeElementParser? parser]) {
    var value = _options[key];

    if (value == null) {
      var keyLC = normalizeKey(key);
      value = _options[keyLC];
    }

    if (value == null) return def;

    parser ??= TypeParser.parserFor<T>(obj: def);
    if (parser != null) {
      // A parser returns `null` for an invalid value: fall back to [def].
      return parser(value) as T? ?? def;
    } else {
      return value as T;
    }
  }

  bool optionMatches(String key, Pattern pattern) {
    var val = optionAsString(key);
    if (val == null) return false;

    return _matches(pattern, val);
  }

  int? optionAsInt(String key, [int? def]) =>
      option<int>(key, def, TypeParser.parseInt);

  double? optionAsDouble(String key, [double? def]) =>
      option<double>(key, def, TypeParser.parseDouble);

  String? optionAsString(String key, [String? def]) =>
      option<String>(key, def, TypeParser.parseString);

  bool? optionAsBool(String key, [bool? def]) =>
      option<bool>(key, def, TypeParser.parseBool);

  List? optionAsList(String key, [List? def]) =>
      option<List>(key, def, TypeParser.parseList);

  Set? optionAsSet(String key, [Set? def]) =>
      option<Set>(key, def, TypeParser.parseSet);

  Map? optionAsMap(String key, [Map? def]) =>
      option<Map>(key, def, TypeParser.parseMap);

  /// Adds the flag [key] (normalized with [normalizeKey]).
  ///
  /// A flag that is a number (`addFlag('5')`) can't be given on a command
  /// line: [toList] emits `-5`, which [ArgsSimple.parse] reads as an argument.
  void addFlag(String key) => _flags.add(normalizeKey(key));

  bool flag<T>(String key) {
    if (_flags.contains(key)) return true;
    var keyLC = normalizeKey(key);
    return _flags.contains(keyLC);
  }

  bool? flagOr<T>(String key, bool? def) {
    if (_flags.contains(key)) return true;
    var keyLC = normalizeKey(key);
    var found = _flags.contains(keyLC);
    if (found) return true;
    return def;
  }

  void putProperty(String key, Object value) =>
      _properties[normalizeKey(key)] = value;

  T? property<T>(String key, [T? def, TypeElementParser? parser]) {
    var value = _properties[key];

    if (value == null) {
      var keyLC = normalizeKey(key);
      value = _properties[keyLC];
    }

    if (value == null) return def;

    parser ??= TypeParser.parserFor<T>(obj: def);
    if (parser != null) {
      // A parser returns `null` for an invalid value: fall back to [def].
      return parser(value) as T? ?? def;
    } else {
      return value as T;
    }
  }

  bool propertyMatches(String key, Pattern pattern) {
    var val = propertyAsString(key);
    if (val == null) return false;

    return _matches(pattern, val);
  }

  int? propertyAsInt(String key, [int? def]) =>
      property<int>(key, def, TypeParser.parseInt);

  double? propertyAsDouble(String key, [double? def]) =>
      property<double>(key, def, TypeParser.parseDouble);

  String? propertyAsString(String key, [String? def]) =>
      property<String>(key, def, TypeParser.parseString);

  bool? propertyAsBool(String key, [bool? def]) =>
      property<bool>(key, def, TypeParser.parseBool);

  List? propertyAsList(String key, [List? def]) =>
      property<List>(key, def, TypeParser.parseList);

  Set? propertyAsSet(String key, [Set? def]) =>
      property<Set>(key, def, TypeParser.parseSet);

  Map? propertyAsMap(String key, [Map? def]) =>
      property<Map>(key, def, TypeParser.parseMap);

  bool _matches(Pattern pattern, String val) {
    if (pattern is RegExp) {
      return pattern.hasMatch(val);
    } else {
      return pattern.matchAsPrefix(val) != null;
    }
  }

  static final _regExpNonNormalizedKey = RegExp(
    r'[^\p{L}\p{M}\p{N}]',
    unicode: true,
  );

  /// Normalizes a flag, option or property key, making keys case-insensitive
  /// and insensitive to separators (`--sys-config`, `--sys_config` and
  /// `--SysConfig` are the same key):
  /// - The key is lower-cased.
  /// - Every character that is not a Unicode letter, mark or digit (`-`, `_`,
  ///   `.`, `=`, spaces, punctuation, symbols, emoji) is removed.
  ///
  /// Non-ASCII letters and digits are kept: `--Ünïcode` is `ünïcode`.
  static String normalizeKey(String key) =>
      key.toLowerCase().replaceAll(_regExpNonNormalizedKey, '');

  /// Serializes back to a command line that [ArgsSimple.parse] parses to the
  /// same arguments, flags, options and properties.
  ///
  /// The order is: arguments, flags, options, properties. If an argument
  /// starts with `-` (and is not a negative number), the arguments are
  /// emitted last, after a `--` (end of options).
  List<String> toList() {
    var endOfOptions = _arguments.any(_needsEndOfOptions);
    return [
      if (!endOfOptions) ..._arguments,
      ..._flags.map((e) => '-$e'),
      ..._options.entries.expand((e) {
        var value = e.value;
        // An option given more than once is stored as a `List`
        // (see [ArgsSimple.parse]): emit one `--key value` pair per value.
        var values = value is List ? value : [value];
        // A key from `fromJson(Map)` is not normalized: a raw key with `=`
        // would be split by `parse`.
        var key = normalizeKey(e.key);
        // An empty key can only be given as `--=value` (`--` ends options).
        return key.isEmpty
            ? values.map((v) => '--=$v')
            : values.expand((v) => ['--$key', '$v']);
      }),
      ..._properties.entries.map((e) => '-P${e.key}=${e.value}'),
      if (endOfOptions) ...['--', ..._arguments],
    ];
  }

  /// Returns a JSON-encodable copy: `arguments` and `flags` as [List]s,
  /// `options` and `properties` as [Map]s (empty sections are omitted).
  /// See [ArgsSimple.fromJson].
  Map<String, Object> toJson() => {
    if (_arguments.isNotEmpty) 'arguments': [..._arguments],
    if (_flags.isNotEmpty) 'flags': [..._flags],
    if (_options.isNotEmpty)
      'options': _options.map((k, v) => MapEntry(k, v is List ? [...v] : v)),
    if (_properties.isNotEmpty) 'properties': {..._properties},
  };

  @override
  String toString() => toList().toString();
}
