SocketStream iOS library
========================

Includes iOS implementation of the SocketStream protocol (in Stream.m) and Engine.io protocol (in Socket.m).
Will read / store SocketStream SessionID, auto-reconnect when disconnected, and make RPC / PubSub calls

To connect to localhost:9002, just run:

	stream = [[Stream alloc] initWithHost:@"localhost" port:9002 secure:NO];
	stream.delegate = self;
	[stream connectToServer];


NOTE: This WILL NOT work with current version of SocketStream, it needs to be modified first.

This library is designed to connect to engine.io using only websocket. This means the SessionID needs to be generated on the SocketStream server and sent down to the client.
When the client first start up, it will send a handshake system message in the form of X|<SessionID>, if no SessionID is found, it will send X|null.

When the server receive the handshake, it needs to either respond with X|OK if the SessionID is correct, or X|<New SessionID> if the SessionID is invalid / null.

