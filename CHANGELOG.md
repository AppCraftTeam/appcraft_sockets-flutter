## 0.0.1

* Initial release.
* `WebSocketClient` with an application-defined message type registry:
  `registerMessageType`, `registerJsonMessageType`, `removeMessageType` and
  typed `listenMessages<T>()` streams.
* Automatic reconnection on any close until `disconnect()` is called, with
  configurable attempt limit and interval; message streams survive reconnects.
* `onSocketClose` callback for the point where the client stops reconnecting.
* Mobile, desktop and web support through conditional imports.
