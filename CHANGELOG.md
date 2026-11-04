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
