import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env_config.dart';
import '../l10n/app_localizations.dart';

/// Debug-only server endpoint switcher.
///
/// The persisted value is read before the dependency graph is constructed and
/// therefore requires an app restart. This keeps every Dio/WebSocket client on
/// one origin instead of hot-swapping some clients and leaving others stale.
class DebugServerSettingsDialog extends StatefulWidget {
  const DebugServerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DebugServerSettingsDialog(),
    );
  }

  @override
  State<DebugServerSettingsDialog> createState() =>
      _DebugServerSettingsDialogState();
}

class _DebugServerSettingsDialogState extends State<DebugServerSettingsDialog> {
  late final TextEditingController _controller;
  String? _feedback;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: EnvConfig.runtimeApiBase ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _normalized() {
    final raw = _controller.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return raw;
  }

  Future<void> _test() async {
    final base = _normalized();
    final l10n = AppLocalizations.of(context)!;
    if (base == null) {
      setState(() => _feedback = l10n.loginServerInvalid);
      return;
    }
    setState(() {
      _testing = true;
      _feedback = null;
    });
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (_) => true,
        ),
      ).get<dynamic>('$base/actuator/health');
      if (!mounted) return;
      setState(() {
        _feedback = response.statusCode == 200
            ? l10n.loginServerReachable
            : '${l10n.loginServerUnreachable} (${response.statusCode})';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedback = '${l10n.loginServerUnreachable}: $error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final base = _normalized();
    final l10n = AppLocalizations.of(context)!;
    if (base == null) {
      setState(() => _feedback = l10n.loginServerInvalid);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EnvConfig.runtimeApiBaseKey, base);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loginServerSaved)),
    );
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(EnvConfig.runtimeApiBaseKey);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.loginServerSettings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.loginServerLabel}: ${EnvConfig.apiBase}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: l10n.loginServerHint,
              helperText: l10n.loginServerHint,
            ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedback!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : _test,
          child: Text(l10n.loginServerTest),
        ),
        TextButton(
          onPressed: _clear,
          child: Text(l10n.loginServerReset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _testing ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class DebugServerFooter extends StatelessWidget {
  const DebugServerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => DebugServerSettingsDialog.show(context),
      icon: const Icon(Icons.dns_outlined, size: 14),
      label: Text(
        '${l10n.loginServerLabel}: ${EnvConfig.apiBase}',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
