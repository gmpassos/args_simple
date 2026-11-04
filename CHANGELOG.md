## 1.3.0

- `ArgsSimple.parse`: parsing behaviour changes:
  - `--` now ends option parsing: every following element is an argument, even if it starts with `-` (`['--', '-x']` gives the argument `-x`). It used to be an option with an empty key that consumed the next element.
  - `--key=value` is now split on the first `=`: the option `key` with `value` (which may be empty or contain `=`), without consuming the next element. It used to be the option `keyvalue` consuming the next element as its value. `--key value` is unchanged. `--flag=true` is an option, not a flag (read it with `optionAsBool`).
  - Keys keep Unicode letters and digits: `--Ünïcode` is now `ünïcode` (it used to be `ncode`). Keys are still lower-cased and stripped of `-`, `_`, `.`, spaces, punctuation and symbols, so `--sys-config`, `--sys_config` and `--SysConfig` remain the same key. ASCII keys are unchanged.
  - `-D`/`-P` are a property prefix only when followed by `key=value` (or `key:value`): `-Port`, `-Debug`, `-Dverbose`, `-P` are now flags (`port`, `debug`, `dverbose`, `p`); they used to be the properties `ort`, `ebug`, `verbose` and `''` with an empty value. `-Dkey=value`, `-Pkey=value` and `-Dkey:value` are unchanged.
- `ArgsSimple`:
  - `toList`: arguments starting with `-` (other than negative numbers) are emitted after `--`, so `parse -> toList -> parse` round-trips (an argument `-x` added in code used to come back as a flag). An option with an empty key is emitted as `--=value`.
  - `toJson`: `flags` is now a `List` (it was a `Set`, so `jsonEncode(args.toJson())` failed when there were flags). The `options` lists are copies.
  - `fromJson`: a `Map` in the `toJson` format (only the keys `arguments`, `flags`, `options`, `properties`, with the matching types) now loads all four sections, so `toJson -> fromJson` round-trips. Any other `Map` is still read as options.
  - `normalizeKey`: documented; uses a Unicode-aware character check.
- `TypeParser`:
  - `parserFor`: nullable built-in types (`int?`, `String?`, `List?`, ...) now get the parser of their non-nullable type (it returned `null`), so `option<int?>('port')` parses instead of throwing a `TypeError`.
  - `parseMap`/`parseMapEntry`: a key or value that can't be parsed (`parseMap<String, int>('a=x')`) no longer throws a `TypeError`: the entry is skipped by `parseMap` and `parseMapEntry` returns `def` (consistent with keys without a value in 1.2.1). A nullable type keeps the entry with a `null`. This also applies to `Map`, `MapEntry` and `Iterable` inputs; a one-element `Iterable` is a key without a value.
- README: documented the parsing rules.
- Tests: regression tests for each change (failing on 1.2.1), `--`/`--key=value`/Unicode/`-P`/`-D` round-trips, a randomized `parse -> toList -> parse` property test, and `toJson -> jsonEncode -> fromJson` round-trips. Tests: 127 -> 148. Line coverage: 100%.

## 1.2.1

- `ArgsSimple`:
  - Fixed `argument`/`option`/`property` (and the typed `*AsInt`, `*AsDouble`, `*AsBool`, ... accessors) throwing a `TypeError` when a value can't be parsed (e.g. `--port abc` with `optionAsInt('port', 8080)`): they now return the default (or `null`).
- `TypeParser`:
  - Fixed `parseMap`/`parseMapEntry` throwing a `TypeError` for a key without a value (`parseMap<String, String>('a;b=1')`) when the value type is non-nullable: the entry is now skipped by `parseMap` (`{'b': '1'}`) and `parseMapEntry` returns `def`. A nullable/dynamic value type still keeps the key with a `null` value.
- Tests: added edge-case tests (empty input, `--`, `--key=value`, `=` in values, repeated options/flags/properties, `-P`/`-D` prefixes, negative numbers vs. flags, quoting, unicode), `parse -> toList -> parse` round-trips, and end-to-end tests running real processes (the example CLI, and a script comparing real `argv` parsing with in-process parsing). Tests: 69 -> 127. Line coverage: 99.3% -> 100%.
- GitHub CI: the Codecov upload now uses the `CODECOV_TOKEN` secret and fails CI on error.

## 1.2.0

- `ArgsSimple`:
  - `toList`: an option given more than once (stored as a `List`) is now emitted as one `--key value` pair per value, so `toList` round-trips through `parse` (it used to emit `--key [v1, v2]`).
- `TypeParser`:
  - `parseMapEntry`/`parseMap`: fixed whitespace around the key/value delimiter leaking into the value (`'a = 1'` gave the value `'= 1'`).
  - Use `Iterable.nonNulls` instead of the deprecated `whereNotNull` from `package:collection`.
- Removed unnecessary library names.
- Removed dependency `collection` (no longer used).
- Tests: added unit tests for `TypeParser`, `TypeParserIO`, the `ArgsSimple` accessors, `fromJson`, serialization and the `dart:io` extension, plus integration tests running the example CLI. Line coverage: 31.5% -> 99.3%.
- GitHub CI: `actions/checkout@v7`, `codecov/codecov-action@v7`; tests run on SDK 3.13.0 and stable.

- sdk: ^3.13.0
- yaml: ^3.1.4
- lints: ^6.1.0
- test: ^1.33.0
- dependency_validator: ^5.1.0
- coverage: ^1.16.0

## 1.1.0

- `ArgsSimple`:
  - `parse`: allow multiple values for the same option.
  - Added `flagOr`.

- sdk: '>=3.0.0 <4.0.0'
- collection: ^1.18.0
- yaml: ^3.1.2
- lints: ^2.1.1
- test: ^1.24.9
- dependency_validator: ^3.2.2
- coverage: ^1.7.1

## 1.0.0

- Initial version.
