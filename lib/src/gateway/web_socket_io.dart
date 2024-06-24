import 'dart:io';

typedef PlatformWebSocket = WebSocket;

Future<PlatformWebSocket> createWebSocket(String url) async {
  return WebSocket.connect(url);
}

Stream<dynamic> getWebSocketOnMessage(WebSocket ws) {
  return ws;
}

Stream getWebSocketOnOpen(WebSocket ws) {
  return ws.done.asStream();
}

void setWebSocketBinaryType(WebSocket ws) {
  // No binaryType setter for io.WebSocket
}

Stream getWebSocketOnClose(WebSocket ws) {
  return ws.done.asStream();
}

void closeWebSocket(WebSocket ws, int? code) {
  ws.close(code ?? 1000);
}

void sendWebSocketData(WebSocket ws, dynamic data) {
  ws.add(data);
}

const bool isWeb = false;
