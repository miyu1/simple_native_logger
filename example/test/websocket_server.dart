import 'dart:async';
import 'dart:io';

// websocket server to pass command from sender to listener
//
// <sender>      <server>   <listener>
//               start
// waiting    ->
//                        <- ready
//
// ok         <-
// <command>  ->
//                        -> <command>
//                        <- <response>
// <response> <-
// exit       ->
// (close socket)
//                        -> exit
//                           (close socket)
//               end
void main(List<String> args) async {
  print('start: $args');

  final ipaddress = args[0];
  print("address: $ipaddress");
  var server = await HttpServer.bind(ipaddress, 4040);

  WebSocket? listener;
  WebSocket? sender;

  runZonedGuarded(() async {
    server.listen((req) async {
      if (req.uri.path == "/ws") {
        var socket = await WebSocketTransformer.upgrade(req);
        socket.listen(
          (data){
            print("data: $data");
            // handshake
            if (data == "ready") {
              listener = socket;
              print("listener connected");
              sender?.add("ok");
            } else if(data == "waiting") {
              sender = socket;
              print("sender connected");
              if (listener != null) {
                sender?.add("ok");
              }
            } else if(socket == sender){
              listener?.add(data);
            } else  if(socket == listener) {
              sender?.add(data);
            }
          },
          onDone: () {
            if (socket == sender) {
              print("sender closed");
              sender = null;
            } else if(socket == listener) {
              print("listener closed");
              listener = null;
            }
            if (sender == null && listener == null) {
              throw ExitException("end of process");
            }
          },
        );
      }
    });
  },
  (error, stack) {
    //print("error: $error");
    if (error is ExitException) {
      server.close();
      exit(0);
    }
  }
  ); 
}

class ExitException implements Exception {
  dynamic message;

  ExitException(this.message);

  @override
  String toString() {
    return "ExitException: $message";
  }
}