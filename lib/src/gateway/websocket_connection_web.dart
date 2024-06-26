import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class WebSocket {
  final html.WebSocket _webSocket;
  int? closeCode;
  Future<void> done;

  WebSocket._(this._webSocket)
      : done = _webSocket.onClose.first.then((_) => Future.value());

  static Future<WebSocket> connect(String url) async {
    final ws = html.WebSocket(url);
    await ws.onOpen.first;
    return WebSocket._(ws);
  }

  Stream<String> get onMessage => _webSocket.onMessage
      .map((event) => (event as html.MessageEvent).data as String);
  Stream<html.CloseEvent> get onClose => _webSocket.onClose;
  Stream<html.Event> get onOpen => _webSocket.onOpen;

  void add(dynamic data) {
    if (data is String) {
      _webSocket.send(data);
    } else if (data is List<int>) {
      _webSocket.sendByteBuffer(Uint8List.fromList(data).buffer);
    }
  }

  Future<void> close([int code = 1000]) async {
    _webSocket.close(code);
    await done;
  }
}
