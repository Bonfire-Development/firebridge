import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

class WebSocket {
  final io.WebSocket _webSocket;
  int? closeCode;
  Future<void> done;

  WebSocket._(this._webSocket)
      : done = _webSocket.done.then((_) => Future.value());

  static Future<WebSocket> connect(String url) async {
    final ws = await io.WebSocket.connect(url);
    return WebSocket._(ws);
  }

  Stream<dynamic> get onMessage =>
      _webSocket.transform(StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data is String) {
            sink.add(data);
          } else if (data is List<int>) {
            sink.add(Uint8List.fromList(data));
          } else if (data is ByteBuffer) {
            sink.add(data.asUint8List());
          } else {
            sink.addError('Unexpected data type');
          }
        },
      ));

  Stream get onClose => _webSocket.done.asStream();
  Stream get onOpen => Stream.value(null);

  void add(dynamic data) {
    if (data is String) {
      _webSocket.add(data);
    } else if (data is List<int>) {
      _webSocket.add(data);
    }
  }

  Future<void> close([int code = 1000]) async {
    _webSocket.close(code);
    await done;
  }
}
