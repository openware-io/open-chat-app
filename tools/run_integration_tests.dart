import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    _printUsage();
    return;
  }

  final devices = await _loadDevices();
  final device = _selectDevice(devices, options.deviceId);
  final timestamp = DateTime.now();
  final reportDirectory = Directory(
    options.reportDirectory ??
        'build/test-reports/integration-${_fileTimestamp(timestamp)}',
  );
  await reportDirectory.create(recursive: true);

  final eventsFile = File('${reportDirectory.path}/events.jsonl');
  final stderrFile = File('${reportDirectory.path}/stderr.log');
  final eventsSink = eventsFile.openWrite();
  final stderrSink = stderrFile.openWrite();
  final results = <int, _TestResult>{};
  final steps = <_TestStep>[];
  var runnerReportedSuccess = false;

  stdout.writeln('设备：${device.name} (${device.id})');
  stdout.writeln('测试：${options.target}');

  final flutterArguments = <String>[
    'test',
    options.target,
    '-d',
    device.id,
    '--machine',
    ...options.flutterArguments,
  ];
  final process = await Process.start(
    'flutter',
    flutterArguments,
    runInShell: Platform.isWindows,
  );

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
    eventsSink.writeln(line);
    final event = _decodeEvent(line);
    if (event == null) {
      stdout.writeln(line);
      return;
    }

    switch (event['type']) {
      case 'testStart':
        final test = event['test'] as Map<String, dynamic>?;
        final id = (test?['id'] as num?)?.toInt();
        if (test != null && id != null) {
          final result = _TestResult(
            id: id,
            name: test['name']?.toString() ?? '未命名测试',
            path: test['url']?.toString() ?? '',
            startedAtMs: (event['time'] as num?)?.toInt() ?? 0,
          );
          results[id] = result;
          stdout.writeln('  开始  ${result.name}');
        }
        break;
      case 'error':
        final id = (event['testID'] as num?)?.toInt();
        if (id != null) {
          results[id]?.errors.add(
                _TestError(
                  message: event['error']?.toString() ?? '未知错误',
                  stackTrace: event['stackTrace']?.toString() ?? '',
                ),
              );
        }
        break;
      case 'testDone':
        final id = (event['testID'] as num?)?.toInt();
        final result = id == null ? null : results[id];
        if (result != null) {
          result
            ..status = event['result']?.toString() ?? 'unknown'
            ..skipped = event['skipped'] == true
            ..endedAtMs = (event['time'] as num?)?.toInt() ?? 0;
          stdout.writeln(
            '  ${result.passed ? '通过' : result.skipped ? '跳过' : '失败'}  '
            '${result.name} (${result.durationMs} ms)',
          );
        }
        break;
      case 'done':
        runnerReportedSuccess = event['success'] == true;
        break;
      case 'print':
        final message = event['message']?.toString() ?? '';
        const prefix = '[GV_STEP] ';
        if (message.startsWith(prefix)) {
          final step = _TestStep(
            name: message.substring(prefix.length).trim(),
            timeMs: (event['time'] as num?)?.toInt() ?? 0,
          );
          steps.add(step);
          stdout.writeln('  步骤  ${step.name}');
        }
        break;
    }
  });

  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
    stderrSink.writeln(line);
    stderr.writeln(line);
  });

  final processExitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  await eventsSink.close();
  await stderrSink.close();

  final finishedAt = DateTime.now();
  final run = _TestRun(
    startedAt: timestamp,
    finishedAt: finishedAt,
    device: device,
    target: options.target,
    command: 'flutter ${flutterArguments.map(_redactArgument).join(' ')}',
    exitCode: processExitCode,
    success: processExitCode == 0 && runnerReportedSuccess,
    results: results.values.toList(),
    steps: steps,
  );

  await File('${reportDirectory.path}/report.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(run.toJson()),
  );
  final reportFile = File('${reportDirectory.path}/report.html');
  await reportFile.writeAsString(_buildHtmlReport(run));

  stdout.writeln();
  stdout.writeln(run.success ? '集成测试通过。' : '集成测试失败。');
  stdout.writeln('HTML 报告：${reportFile.absolute.path}');
  stdout.writeln('原始结果：${eventsFile.absolute.path}');
  exitCode = run.success ? 0 : (processExitCode == 0 ? 1 : processExitCode);
}

Future<List<_Device>> _loadDevices() async {
  final result = await Process.run(
    'flutter',
    const ['devices', '--machine'],
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    throw StateError('读取 Flutter 设备失败：\n${result.stderr}');
  }

  final output = result.stdout.toString().trim();
  final jsonStart = output.indexOf('[');
  final jsonEnd = output.lastIndexOf(']');
  if (jsonStart < 0 || jsonEnd < jsonStart) {
    throw StateError('Flutter 没有返回有效的设备列表。');
  }
  final value = jsonDecode(output.substring(jsonStart, jsonEnd + 1));
  return (value as List<dynamic>)
      .map((item) => _Device.fromJson(item as Map<String, dynamic>))
      .where((device) => device.isSupported)
      .toList();
}

_Device _selectDevice(List<_Device> devices, String? requestedId) {
  if (requestedId != null) {
    return devices.firstWhere(
      (device) => device.id == requestedId,
      orElse: () => throw StateError(
        '没有找到设备 "$requestedId"。\n${_deviceList(devices)}',
      ),
    );
  }

  final mobileDevices = devices.where((device) => device.isMobile).toList();
  if (mobileDevices.length == 1) {
    return mobileDevices.single;
  }

  final physicalMobileDevices =
      mobileDevices.where((device) => !device.emulator).toList();
  if (physicalMobileDevices.length == 1) {
    return physicalMobileDevices.single;
  }

  if (mobileDevices.isEmpty) {
    throw StateError(
      '没有找到 Android 或 iOS 设备。请先连接手机或启动模拟器。\n'
      '${_deviceList(devices)}',
    );
  }

  throw StateError(
    '检测到多台移动设备，请使用 --device 指定其中一台：\n'
    '${_deviceList(mobileDevices)}',
  );
}

String _deviceList(List<_Device> devices) => devices.isEmpty
    ? '  （没有可用设备）'
    : devices
        .map((device) =>
            '  ${device.id}  ${device.name}  ${device.targetPlatform}')
        .join('\n');

Map<String, dynamic>? _decodeEvent(String line) {
  try {
    final value = jsonDecode(line);
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}

String _buildHtmlReport(_TestRun run) {
  final passed = run.results.where((result) => result.passed).length;
  final failed = run.results.where((result) => result.failed).length;
  final skipped = run.results.where((result) => result.skipped).length;
  final rows = run.results.map((result) {
    final statusClass = result.passed
        ? 'passed'
        : result.skipped
            ? 'skipped'
            : 'failed';
    final statusText = result.passed
        ? '通过'
        : result.skipped
            ? '跳过'
            : '失败';
    final errors = result.errors.isEmpty
        ? ''
        : '<details><summary>查看错误</summary><pre>${_htmlEscape(result.errors.map((error) => '${error.message}\n${error.stackTrace}').join('\n\n'))}</pre></details>';
    return '''
      <tr>
        <td><span class="status $statusClass">$statusText</span></td>
        <td>${_htmlEscape(result.name)}$errors</td>
        <td>${_htmlEscape(result.path)}</td>
        <td>${result.durationMs} ms</td>
      </tr>''';
  }).join();
  final stepItems = run.steps.isEmpty
      ? '<p class="muted">本次测试没有输出流程步骤。</p>'
      : '<ol class="steps">${run.steps.map((step) => '<li><span>${_htmlEscape(step.name)}</span><small>${step.timeMs} ms</small></li>').join()}</ol>';

  return '''<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>GV Chat 集成测试报告</title>
  <style>
    :root { color-scheme: light dark; font-family: system-ui, "Microsoft YaHei", sans-serif; }
    body { max-width: 1100px; margin: 40px auto; padding: 0 24px; background: #f5f7fb; color: #172033; }
    h1 { margin-bottom: 6px; }
    .muted { color: #667085; }
    .summary { display: grid; grid-template-columns: repeat(4, minmax(120px, 1fr)); gap: 12px; margin: 24px 0; }
    .card, .panel { background: #fff; border: 1px solid #e4e7ec; border-radius: 12px; box-shadow: 0 3px 12px #1018280d; }
    .card { padding: 18px; }
    .card strong { display: block; font-size: 28px; margin-top: 4px; }
    .panel { padding: 20px; margin-bottom: 20px; overflow-x: auto; }
    .overall { color: ${run.success ? '#067647' : '#b42318'}; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 12px 10px; border-bottom: 1px solid #eaecf0; text-align: left; vertical-align: top; }
    .status { display: inline-block; border-radius: 999px; padding: 3px 10px; font-weight: 650; }
    .passed { background: #dcfae6; color: #067647; }
    .failed { background: #fee4e2; color: #b42318; }
    .skipped { background: #f2f4f7; color: #475467; }
    pre { white-space: pre-wrap; background: #101828; color: #f2f4f7; padding: 14px; border-radius: 8px; }
    .steps { padding-left: 24px; }
    .steps li { padding: 7px 0; }
    .steps small { margin-left: 12px; color: #667085; }
    code { word-break: break-all; }
    @media (prefers-color-scheme: dark) {
      body { background: #101828; color: #f2f4f7; }
      .card, .panel { background: #1d2939; border-color: #344054; }
      .muted { color: #98a2b3; }
      th, td { border-color: #344054; }
    }
    @media (max-width: 720px) { .summary { grid-template-columns: repeat(2, 1fr); } }
  </style>
</head>
<body>
  <h1>GV Chat 集成测试报告</h1>
  <div class="muted">${_htmlEscape(run.startedAt.toLocal().toString())}</div>
  <div class="summary">
    <div class="card">结果<strong class="overall">${run.success ? '通过' : '失败'}</strong></div>
    <div class="card">通过<strong>$passed</strong></div>
    <div class="card">失败<strong>$failed</strong></div>
    <div class="card">跳过<strong>$skipped</strong></div>
  </div>
  <section class="panel">
    <h2>运行信息</h2>
    <p><b>设备：</b>${_htmlEscape(run.device.name)} (${_htmlEscape(run.device.id)})</p>
    <p><b>平台：</b>${_htmlEscape(run.device.targetPlatform)} · ${_htmlEscape(run.device.sdk)}</p>
    <p><b>测试目标：</b>${_htmlEscape(run.target)}</p>
    <p><b>总耗时：</b>${run.duration.inSeconds} 秒</p>
    <p><b>命令：</b><code>${_htmlEscape(run.command)}</code></p>
  </section>
  <section class="panel">
    <h2>操作步骤</h2>
    $stepItems
  </section>
  <section class="panel">
    <h2>测试明细</h2>
    <table>
      <thead><tr><th>结果</th><th>测试</th><th>文件</th><th>耗时</th></tr></thead>
      <tbody>$rows</tbody>
    </table>
  </section>
  <section class="panel">
    <h2>原始文件</h2>
    <p><a href="events.jsonl">events.jsonl</a> · <a href="report.json">report.json</a> · <a href="stderr.log">stderr.log</a></p>
  </section>
</body>
</html>''';
}

String _htmlEscape(String value) => const HtmlEscape().convert(value);

String _fileTimestamp(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}-'
    '${value.hour.toString().padLeft(2, '0')}'
    '${value.minute.toString().padLeft(2, '0')}'
    '${value.second.toString().padLeft(2, '0')}';

String _quoteArgument(String value) =>
    value.contains(' ') ? '"${value.replaceAll('"', '\\"')}"' : value;

String _redactArgument(String value) {
  var separator = value.indexOf('=');
  if (separator < 0) return _quoteArgument(value);
  if (value.startsWith('--dart-define=')) {
    separator = value.indexOf('=', '--dart-define='.length);
    if (separator < 0) return _quoteArgument(value);
  }
  final name = value.substring(0, separator).toUpperCase();
  const sensitiveTerms = ['PASSWORD', 'TOKEN', 'SECRET', 'APPKEY', 'API_KEY'];
  if (sensitiveTerms.any(name.contains)) {
    return '${value.substring(0, separator + 1)}***';
  }
  return _quoteArgument(value);
}

void _printUsage() {
  stdout.writeln('''
运行 GV Chat 的 Flutter 集成测试并生成 HTML 报告。

用法：
  dart run tools/run_integration_tests.dart
  dart run tools/run_integration_tests.dart --device=<设备ID>

选项：
  -d, --device       指定设备；只有连接多台手机时才需要
  -t, --target       测试文件或目录，默认 integration_test
      --report-dir   自定义报告目录
  -h, --help         显示帮助

未识别的参数会继续传给 flutter test，例如：
  --dart-define=GV_API_BASE=https://example.com
''');
}

class _Options {
  _Options({
    required this.target,
    required this.flutterArguments,
    this.deviceId,
    this.reportDirectory,
    this.showHelp = false,
  });

  final String target;
  final String? deviceId;
  final String? reportDirectory;
  final List<String> flutterArguments;
  final bool showHelp;

  factory _Options.parse(List<String> arguments) {
    var target = 'integration_test';
    String? deviceId;
    String? reportDirectory;
    var showHelp = false;
    final flutterArguments = <String>[];

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      String nextValue(String option) {
        if (index + 1 >= arguments.length) {
          throw ArgumentError('选项 $option 缺少参数。');
        }
        return arguments[++index];
      }

      if (argument == '-h' || argument == '--help') {
        showHelp = true;
      } else if (argument == '-d' || argument == '--device') {
        deviceId = nextValue(argument);
      } else if (argument.startsWith('--device=')) {
        deviceId = argument.substring('--device='.length);
      } else if (argument == '-t' || argument == '--target') {
        target = nextValue(argument);
      } else if (argument.startsWith('--target=')) {
        target = argument.substring('--target='.length);
      } else if (argument == '--report-dir') {
        reportDirectory = nextValue(argument);
      } else if (argument.startsWith('--report-dir=')) {
        reportDirectory = argument.substring('--report-dir='.length);
      } else {
        flutterArguments.add(argument);
      }
    }

    return _Options(
      target: target,
      deviceId: deviceId,
      reportDirectory: reportDirectory,
      flutterArguments: flutterArguments,
      showHelp: showHelp,
    );
  }
}

class _Device {
  const _Device({
    required this.id,
    required this.name,
    required this.targetPlatform,
    required this.sdk,
    required this.emulator,
    required this.isSupported,
  });

  final String id;
  final String name;
  final String targetPlatform;
  final String sdk;
  final bool emulator;
  final bool isSupported;

  bool get isMobile =>
      targetPlatform.startsWith('android') || targetPlatform.startsWith('ios');

  factory _Device.fromJson(Map<String, dynamic> json) => _Device(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '未知设备',
        targetPlatform: json['targetPlatform']?.toString() ?? 'unknown',
        sdk: json['sdk']?.toString() ?? '',
        emulator: json['emulator'] == true,
        isSupported: json['isSupported'] != false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetPlatform': targetPlatform,
        'sdk': sdk,
        'emulator': emulator,
      };
}

class _TestError {
  const _TestError({required this.message, required this.stackTrace});

  final String message;
  final String stackTrace;

  Map<String, dynamic> toJson() => {
        'message': message,
        'stackTrace': stackTrace,
      };
}

class _TestStep {
  const _TestStep({required this.name, required this.timeMs});

  final String name;
  final int timeMs;

  Map<String, dynamic> toJson() => {
        'name': name,
        'timeMs': timeMs,
      };
}

class _TestResult {
  _TestResult({
    required this.id,
    required this.name,
    required this.path,
    required this.startedAtMs,
  });

  final int id;
  final String name;
  final String path;
  final int startedAtMs;
  final List<_TestError> errors = [];
  int endedAtMs = 0;
  String status = 'running';
  bool skipped = false;

  int get durationMs => endedAtMs > startedAtMs ? endedAtMs - startedAtMs : 0;
  bool get passed => status == 'success' && !skipped;
  bool get failed => !passed && !skipped;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'status': status,
        'skipped': skipped,
        'durationMs': durationMs,
        'errors': errors.map((error) => error.toJson()).toList(),
      };
}

class _TestRun {
  const _TestRun({
    required this.startedAt,
    required this.finishedAt,
    required this.device,
    required this.target,
    required this.command,
    required this.exitCode,
    required this.success,
    required this.results,
    required this.steps,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final _Device device;
  final String target;
  final String command;
  final int exitCode;
  final bool success;
  final List<_TestResult> results;
  final List<_TestStep> steps;

  Duration get duration => finishedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'success': success,
        'exitCode': exitCode,
        'device': device.toJson(),
        'target': target,
        'command': command,
        'tests': results.map((result) => result.toJson()).toList(),
        'steps': steps.map((step) => step.toJson()).toList(),
      };
}
