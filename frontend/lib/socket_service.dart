import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(Function(dynamic) onEvent) {
    socket = IO.io(
      'http://localhost:3000', // backend NestJS
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('🟢 Conectado a VOLTIA backend');
    });

    socket.on('map_event', (data) {
      print('📡 Evento recibido: $data');
      onEvent(data);
    });

    socket.onDisconnect((_) {
      print('🔴 Desconectado');
    });
  }

  void sendEvent(dynamic data) {
    socket.emit('map_event', data);
  }
}