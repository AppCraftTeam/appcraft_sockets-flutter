# appcraft_sockets

A typed WebSocket client for Flutter that stays connected.

The package knows nothing about your protocol. You register the message types
your backend speaks — each one with a predicate that recognises it and a mapper
that builds your model — and then consume them as ordinary typed streams.

## Features

- **Typed message streams.** `listenMessages<ChatMessage>()` instead of decoding
  `dynamic` at every call site.
- **Protocol stays in your app.** Message recognition is a predicate you write,
  so any framing works: a `type` field, a URL segment, plain text, anything.
- **Automatic reconnection.** Every close reconnects, with a configurable delay
  and attempt limit. Message streams survive reconnects.
- **JSON and raw handlers.** Register a type against the decoded JSON object or
  against the raw frame.
- **Mobile, desktop and web.** `dart:io` sockets on native platforms,
  `package:web` in the browser, picked by conditional import. WebAssembly
  builds are supported.
- **One dependency.** `package:web`, maintained by the Dart team, and nothing
  else.

## Getting started

```yaml
dependencies:
  appcraft_sockets: ^0.0.1
```

```dart
import 'package:appcraft_sockets/appcraft_sockets.dart';
```

## Usage

### Create a client

```dart
final client = WebSocketClient(const WebSocketClientOptions(
  serverUrl: 'wss://example.com/socket',
));
```

### Register the message types

Handlers are matched in registration order, so register specific types before
catch-all ones.

`registerJsonMessageType` receives the frame already decoded with `jsonDecode`.
Frames that are not valid JSON are skipped by these handlers.

```dart
client.registerJsonMessageType<ChatMessage>(
  (json) => json is Map && json['type'] == 'chat',
  (json) => ChatMessage.fromJson((json! as Map).cast<String, dynamic>()),
);
```

`registerMessageType` receives the frame as it arrived, without decoding.

```dart
client.registerMessageType<Pong>(
  (frame) => frame == 'pong',
  (frame) => const Pong(),
);
```

A predicate or a mapper that throws does not break the delivery of the frame to
the other registered types: the failure is reported as an error event on the
stream of the type it was registered for. A predicate that throws leaves the
frame unclaimed, a mapper that throws claims it.

### Listen and send

```dart
client.listenMessages<ChatMessage>().listen((message) => print(message.text));

await client.connect();

client.sendJsonMessage(ChatMessage(text: 'hi'));
```

`listenMessages<T>()` returns the stream of the first handler that produces `T`
or a subtype of it, so a handler registered for `ChatMessage` is also reachable
through `listenMessages<Message>()` if `ChatMessage extends Message`. When no
handler matches it throws `MissingMessageHandlerException<T>`.

The streams are broadcast streams and can be listened to before connecting.

`sendJsonMessage` encodes its argument with `jsonEncode`, so the argument must
either be a plain JSON-compatible value or expose a `toJson()` method. It throws
`SocketClosedException` when the connection is not open.

### Stop listening for a type

```dart
client.removeMessageType<ChatMessage>();
```

Removes every handler producing `ChatMessage`, both the JSON and the raw ones,
and closes the streams handed out for them. Subtypes are matched exactly as
`listenMessages` matches them, so removing a base type also removes the
handlers of its subtypes — `removeMessageType<Object>()` drops all of them.

### Close

```dart
await client.disconnect(); // closes and stops reconnecting
await client.dispose();    // disconnects, then closes all message streams
```

`dispose()` also drops the registered message types and the `onSocketClose`
callback. The client itself stays usable: register the types again and call
`connect()` to start over.

## Reconnection

While `disconnect()` has not been called, every closed connection is
re-established, regardless of the close code the peer reported — a clean
server-side shutdown and a dropped network are treated the same way.

`reconnectInterval` is waited out before each attempt, including the first one
after a connection is lost, so a server that accepts a connection and drops it
immediately is polled rather than hammered.

`reconnectAttempts` limits the number of tries per connection loss and applies
to the initial `connect()` as well; `0` (the default) means unlimited. The
counter resets once a connection is established.
`connect()` throws `WebSocketServerConnectionException` when the attempts run
out — with the default `0` it therefore never fails on its own, and its future
completes only once the connection is established. A `disconnect()` while the
attempt is still in flight completes that future normally instead of throwing:
the caller has asked for the connection to be dropped. When the attempts run out
during a *re*connect there is no caller left to throw at, so the callback
registered with `onSocketClose` is invoked instead:

```dart
client.onSocketClose(() => print('Gave up reconnecting'));
```

That callback also fires after a deliberate `disconnect()`. One callback is kept
at a time: registering a second one replaces the first.

`isOpened`, `isConnecting` and `isClosed` report the current state. `isClosed` is
also true while the client waits out `reconnectInterval` between two attempts, so
it does not mean the client has given up — giving up is what the `onSocketClose`
callback reports.

## Options

| Option                   | Default    | Meaning                                                             |
|--------------------------|------------|---------------------------------------------------------------------|
| `serverUrl`              | required   | WebSocket URL to connect to.                                        |
| `reconnectAttempts`      | `0`        | Attempts per connection loss; `0` is unlimited.                     |
| `reconnectInterval`      | `2 s`      | Delay before every attempt except the first one of `connect()`.     |
| `singleMessageTypeMatch` | `true`     | Deliver a frame to the first matching handler only.                 |
| `onLog`                  | `logToDeveloper` | Called with connection lifecycle messages; `null` logs nothing.|

Set `singleMessageTypeMatch` to `false` when one frame should reach several
registered types.

`onLog` decides where the lifecycle messages go and what they look like. By
default they are handed to `dart:developer` by `logToDeveloper`, tagged
`appcraft_sockets`, so a Flutter app shows them in the debug console and in the
DevTools logging view and can filter them by that tag. A plain Dart process with
no VM service attached drops those, so a console program wants `onLog: print`,
and `onLog: null` turns logging off altogether.

```dart
WebSocketClientOptions(
  serverUrl: 'wss://example.com/socket',
  onLog: print, // or null for silence, or the logger the app already has
);
```

Only text frames are delivered to handlers; binary frames are ignored.

## Example

[`example/main.dart`](example/main.dart) is a runnable console example.
[`examples/chat_app`](examples/chat_app) is a full Flutter chat application
built on the package.

## Additional information

Issues and pull requests are welcome at the
[repository](https://github.com/AppCraftTeam/appcraft-sockets-flutter).
