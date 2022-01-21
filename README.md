# args_simple

[![pub package](https://img.shields.io/pub/v/args_simple.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/args_simple)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/args_simple)](https://app.codecov.io/gh/gmpassos/args_simple)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/args_simple/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/args_simple/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/args_simple?logo=git&logoColor=white)](https://github.com/gmpassos/args_simple/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/args_simple/latest?logo=git&logoColor=white)](https://github.com/gmpassos/args_simple/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/args_simple?logo=git&logoColor=white)](https://github.com/gmpassos/args_simple/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/args_simple?logo=github&logoColor=white)](https://github.com/gmpassos/args_simple/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/args_simple?logo=github&logoColor=white)](https://github.com/gmpassos/args_simple)
[![License](https://img.shields.io/github/license/gmpassos/args_simple?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/args_simple/blob/master/LICENSE)

A simple argument parser and handler, integrated with JSON and dart:io. 

## API Documentation

See the [API Documentation][api_doc] for a full list of functions, classes and extension.

[api_doc]: https://pub.dev/documentation/args_simple/latest/

## Usage

```dart
import 'dart:io';

import 'package:args_simple/args_simple_io.dart';

/// Examples of valid values for the parameter `args`:
///
/// - `/path/config.json --port 81 -verbose`
/// - `/path/config.json -verbose --sys-config /my/sys-config-dir`
/// - `/path/config.json root`
void main(List<String> _args) {
  var args = ArgsSimple.parse(_args);

  if (args.isEmpty) {
    print(
            'USAGE: [%configFile.json] [%user] [--port] [--sys-config %systemConfig] [-verbose]');
    exit(0);
  }

  // Argument #0 is a JSON `File`:
  var config = args.argumentMatches(0, RegExp(r'.json$'))
          ? args.argumentAsFileContentJSON(0)!
          : {};

  // Argument #1 is an optional `String`:
  var user = args.argumentAsString(1, 'guest');

  // Option `sys-config` is a `Directory`:
  var systemConfigDir = args.optionAsDirectory(
          'sys-config', Directory('/default/sys-config-dir'))!;

  // Option `--port` is a `int`, with 8080 as default:
  var port = args.optionAsInt('port', 8080);

  // Check for flag `-verbose`:
  var verbose = args.flag('verbose');

  if (verbose) {
    print('-- Config: $config');
    print('-- User: $user');
    print('-- System Config Dir: $systemConfigDir');
    print('-- Port: $port');
    print('-- Verbose: $verbose');
    print(args);
  }
}
```

## Source

The official source code is [hosted @ GitHub][github_args_simple]:

- https://github.com/gmpassos/args_simple

[github_args_simple]: https://github.com/gmpassos/args_simple

# Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

# Contribution

Any help from the open-source community is always welcome and needed:
- Found an issue?
    - Please fill a bug report with details.
- Wish a feature?
    - Open a feature request with use cases.
- Are you using and liking the project?
    - Promote the project: create an article, do a post or make a donation.
- Are you a developer?
    - Fix a bug and send a pull request.
    - Implement a new feature, like other training algorithms and activation functions.
    - Improve the Unit Tests.
- Have you already helped in any way?
    - **Many thanks from me, the contributors and everybody that uses this project!**

*If you donate 1 hour of your time, you can contribute a lot,
because others will do the same, just be part and start with your 1 hour.*

[tracker]: https://github.com/gmpassos/args_simple/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
