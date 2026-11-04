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
