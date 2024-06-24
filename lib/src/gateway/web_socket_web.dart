import 'dart:html';

typedef PlatformWebSocket = WebSocket;

PlatformWebSocket createWebSocket(String url) {
  return WebSocket(url);
}

Stream<dynamic> getWebSocketOnMessage(WebSocket ws) {
  return ws.onMessage.map((event) => event.data);
}

Stream getWebSocketOnOpen(WebSocket ws) {
  return ws.onOpen;
}

void setWebSocketBinaryType(WebSocket ws) {
  ws.binaryType = 'arraybuffer';
}

Stream getWebSocketOnClose(WebSocket ws) {
  return ws.onClose;
}

void closeWebSocket(WebSocket ws, int? code) {
  ws.close(code ?? 1000);
}

void sendWebSocketData(WebSocket ws, dynamic data) {
  ws.send(data);
}

const bool isWeb = true;
