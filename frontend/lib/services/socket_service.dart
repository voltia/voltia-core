import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;

  void connect(Function(dynamic) onEvent) {
    socket = io.io(
      'http://localhost:3000',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );

    socket.onConnect((_) {
      print('🟢 Socket conectado');
    });

    socket.on('map_event', (data) {
      print('📡 Evento recibido: $data');
      onEvent(data);
    });

    socket.onDisconnect((_) {
      print('🔴 Socket desconectado');
    });

    socket.onError((error) {
      print('❌ Error socket: $error');
    });
  }

  void sendEvent(dynamic data) {
    socket.emit('map_event', data);
  }

  void dispose() {
    socket.dispose();
  }
}