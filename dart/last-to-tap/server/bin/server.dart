import 'dart:io';

import 'package:last_to_tap_server/game.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ??
      (args.isNotEmpty ? int.tryParse(args.first) : null) ??
      3471;
  final hub = GameHub();

  final wsHandler = webSocketHandler((socket, _) {
    hub.attach(socket);
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request request) {
    if (request.url.path == 'health') {
      return Response.ok('ok');
    }
    return wsHandler(request);
  });

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln(
    'Last to Tap server on ws://${server.address.address}:${server.port}',
  );
}
