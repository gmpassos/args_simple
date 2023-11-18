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

  factory ArgsSimple.fromJson(Object json) {
    if (json is List<String>) {
      return ArgsSimple.parse(json);
    } else if (json is List) {
      return ArgsSimple.parse(json.map((e) => '$e').toList());
    }

    var args = ArgsSimple();

    if (json is Map) {
      args._options.addAll(
          json.map((key, value) => MapEntry(key.toString(), value ?? '')));
    } else {
      var s = '$json';
      args._arguments.add(s);
    }

    return args;
  }

  static final RegExp _propertyDelimiter = RegExp(r'[=:]');

  ArgsSimple.parse([List<String> args = const <String>[]]) {
    final length = args.length;

    for (var i = 0; i < length;) {
      var a = args[i];

      if (a.startsWith('--')) {
        var k = normalizeKey(a.substring(2));
        var v = i < length - 1 ? args[i + 1] : '';
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
        i += 2;
      } else if (a.startsWith('-P') || a.startsWith('-D')) {
        var idx = a.indexOf(_propertyDelimiter);
        if (idx > 0) {
          var k = normalizeKey(a.substring(2, idx));
          var v = a.substring(idx + 1);
          _properties[k] = v;
        } else {
          var k = normalizeKey(a.substring(2));
          _properties[k] = '';
        }
        ++i;
      } else if (a.startsWith('-')) {
        var s = a.substring(1);
        var n = num.tryParse(s);
        if (n != null) {
          _arguments.add(a);
        } else {
          var k = normalizeKey(s);
          _flags.add(k);
        }
        ++i;
      } else {
        _arguments.add(a);
        ++i;
      }
    }
  }

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
      return parser(value) as T;
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
      return parser(value) as T;
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
      return parser(value) as T;
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

  static final _regExpNonNormalizedKey = RegExp(r'[^a-z0-9]');

  static String normalizeKey(String key) =>
      key.toLowerCase().replaceAll(_regExpNonNormalizedKey, '').trim();

  List<String> toList() {
    return [
      ..._arguments,
      ..._flags.map((e) => '-$e'),
      ..._options.entries.expand((e) => ['--${e.key}', e.value.toString()]),
      ..._properties.entries.map((e) => '-P${e.key}=${e.value}'),
    ];
  }

  Map<String, Object> toJson() => {
        if (_arguments.isNotEmpty) 'arguments': [..._arguments],
        if (_flags.isNotEmpty) 'flags': {..._flags},
        if (_options.isNotEmpty) 'options': {..._options},
        if (_properties.isNotEmpty) 'properties': {..._properties},
      };

  @override
  String toString() => toList().toString();
}
