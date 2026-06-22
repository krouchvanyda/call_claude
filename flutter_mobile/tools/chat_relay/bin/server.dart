import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Tiny WebSocket relay for the Module 10 chat demo.
///
/// Every connected client sends a JSON envelope `{type, from, payload}`
/// (utf-8). The relay broadcasts each envelope to all OTHER connected
/// clients (the originator is filtered out). No auth, no persistence,
/// no history replay — clients only see messages that arrive while
/// they are connected.
///
/// Usage:
///   dart pub get          # once
///   dart run bin/server.dart           # listens on 0.0.0.0:7777
///   dart run bin/server.dart --port 9000
///
/// Once it's running, point both phones at it:
///   real phone on same Wi-Fi  →  `ws://<your-PC-LAN-IP>:7777`
///   Android emulator          →  ws://10.0.2.2:7777
///   iOS simulator             →  ws://127.0.0.1:7777
void main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('host', defaultsTo: '0.0.0.0', help: 'Bind address.')
    ..addOption('port', defaultsTo: '7777', help: 'Listen port.')
    ..addFlag('verbose', abbr: 'v', help: 'Log every envelope body.');
  final args = parser.parse(argv);
  final host = args['host'] as String;
  final port = int.parse(args['port'] as String);
  final verbose = args['verbose'] as bool;

  final hub = _Hub(verbose: verbose);

  final handler = webSocketHandler((WebSocketChannel ws, _) {
    hub.connect(ws);
  });

  final server = await shelf_io.serve(handler, host, port);
  server.autoCompress = true;
  _log('relay listening on ws://$host:$port');
  _log('LAN: connect phones with ws://<your-PC-IP>:$port');
  _log('emulator: ws://10.0.2.2:$port   simulator: ws://127.0.0.1:$port');
  _log('Press Ctrl+C to stop.');
}

class _Hub {
  _Hub({required this.verbose});
  final bool verbose;
  final Set<_Client> _clients = {};
  int _nextId = 1;

  void connect(WebSocketChannel ws) {
    final client = _Client(id: _nextId++, channel: ws);
    _clients.add(client);
    _log('+ client #${client.id} connected (${_clients.length} total)');

    ws.stream.listen(
      (data) {
        if (data is! String) return;
        Map<String, dynamic> envelope;
        try {
          envelope = jsonDecode(data) as Map<String, dynamic>;
        } catch (e) {
          _log('  client #${client.id} sent invalid JSON: $e');
          return;
        }
        final type = envelope['type'] as String? ?? '(no-type)';
        final from = envelope['from'] as String? ?? '(anon)';

        // The "hello" envelope tags this socket with the user's identity
        // so we can log it usefully and (later) implement targeted sends.
        if (type == 'hello') {
          client.userId = from;
          _log('  client #${client.id} → hello $from');
          return;
        }

        if (verbose) {
          _log('  ↪ #${client.id}($from) $type ${jsonEncode(envelope['payload'])}');
        } else {
          _log('  ↪ #${client.id}($from) $type');
        }
        _broadcast(envelope: data, except: client);
      },
      onDone: () {
        _clients.remove(client);
        _log('- client #${client.id} (${client.userId ?? 'anon'}) gone '
            '(${_clients.length} remain)');
      },
      onError: (Object e) {
        _log('  client #${client.id} stream error: $e');
        _clients.remove(client);
      },
      cancelOnError: true,
    );
  }

  void _broadcast({required String envelope, required _Client except}) {
    for (final c in _clients) {
      if (identical(c, except)) continue;
      try {
        c.channel.sink.add(envelope);
      } catch (e) {
        _log('  failed to deliver to #${c.id}: $e');
      }
    }
  }
}

class _Client {
  _Client({required this.id, required this.channel});
  final int id;
  final WebSocketChannel channel;
  String? userId;
}

void _log(String message) {
  final stamp = DateTime.now().toIso8601String().substring(11, 19);
  stdout.writeln('[$stamp] $message');
}
