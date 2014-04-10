SocketStream iOS library compatible with SocketStream 0.3
=========================================================

Includes iOS implementation of the SocketStream protocol (in Stream.m) and Engine.io protocol (in Socket.m).
Will read / store SocketStream SessionID, watchdog timer / activity timer, auto-reconnect when disconnected, and make RPC / PubSub calls

To connect to localhost:3000, just run:

	stream = [[Stream alloc] initWithHost:@"localhost" port:3000 secure:NO];
	stream.delegate = self;
	[stream connectToServer];


NOTE: This should work with current version of SocketStream.

This library is designed to connect to engine.io using only websocket. This means the SessionID needs to be generated on the SocketStream server and sent down to the client.
When the client first start up, it will send a handshake system message in the form of X|<SessionID>, if no SessionID is found, it will send X|null.

When the server receive the handshake, it needs to either respond with X|OK if the SessionID is correct, or X|<New SessionID> if the SessionID is invalid / null.

