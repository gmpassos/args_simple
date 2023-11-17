import 'dart:io';

import 'package:args_simple/args_simple_io.dart';

/// Examples of valid values for the parameter `args`:
///
/// - `/path/config.json --port 81 -verbose`
/// - `/path/config.json -verbose --sys-config /my/sys-config-dir`
/// - `/path/config.json root`
void main(List<String> argsOrig) {
  var args = ArgsSimple.parse(argsOrig);

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
