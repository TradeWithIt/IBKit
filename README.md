# IBKit – Interactive Brokers API, Swiftified

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/TradeWithIt/IBKit#license) ![Swift](https://img.shields.io/badge/swift-6.1-blue.svg) ![Xcode 15.0+](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg) ![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg) ![Linux](https://img.shields.io/badge/Linux-compatible-green.svg)
 [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-blue.svg)](https://github.com/apple/swift-package-manager)

**IBKit** is a modern Swift implementation of the Interactive Brokers TWS/Gateway API. It enables market data access, historical queries, and automated trading – all with an ergonomic Swift Concurrency interface.

> ⚠️ IBKit is not affiliated with Interactive Brokers and is not an official API.

---

## 🔧 Requirements

- macOS 14.0+
- Swift 6.1+
- Xcode 15+
- [IB Gateway or TWS](https://www.interactivebrokers.com/en/trading/ibgateway-stable.php)

---

## 🚀 Installation

```bash
File > Swift Packages > Add Package Dependency
```

Enter:

```
https://github.com/TradeWithIt/IBKit
```

Select the `main` branch.

---

## 📦 Features

✅ Swift-native `IBContract`/`IBRequest` models  
✅ `AsyncStream`-powered market and historical feeds  
✅ Support for both paper and live trading  
✅ Modular request/response architecture  
✅ Combine-free and compatible with Swift Concurrency

---

## 🧠 Architecture: EventBroadcaster

IBKit introduces `EventBroadcaster`, a minimal `actor` that fans out incoming events to multiple `AsyncStream` consumers. This enables:

- Multiple parallel listeners (e.g., broker + charting tool)
- Backpressure-free async delivery
- Safer lifecycle with automatic teardown

```swift
actor EventBroadcaster<T: Sendable> {
    private var continuations: [AsyncStream<T>.Continuation] = []

    func stream() -> AsyncStream<T> {
        AsyncStream { continuation in
            continuations.append(continuation)
        }
    }

    func yield(_ event: T) {
        continuations.forEach { $0.yield(event) }
    }

    func finish() {
        continuations.forEach { $0.finish() }
        continuations.removeAll()
    }
}
```

---

## 🧪 Example: Query Historical Price Data

```swift
let client = IBClient.paper(id: 999)
try await client.connect()

let contract = IBContract.equity("AAPL", currency: "USD")
let interval = DateInterval.lookback(10, unit: .minute, until: .distantFuture)
let request = IBPriceHistoryRequest(
    requestID: client.nextRequestID,
    contract: contract,
    size: .minute,
    source: .trades,
    lookback: interval
)

for await event in try await client.stream(request: request) {
    switch event {
    case let response as IBPriceHistory:
        response.prices.forEach { print($0) }
    case let error as IBServerError:
        print("⚠️ Error: \(error.message)")
    default: break
    }
}
```

---

## 📊 Example: Real-Time Price Feed

```swift
let contract = IBContract.crypto("BTC", currency: "USD")
let request = IBRealTimeBarRequest(
    requestID: client.nextRequestID,
    contract: contract,
    source: .midpoint
)

for await event in try await client.stream(request: request) {
    if let bar = event as? IBPriceBarUpdate {
        print(bar)
    }
}
```

---

## 🛠 Configuration Tips

In IB Gateway:

- Enable **API access** under *Settings > API > Settings*
- Uncheck **Read-only API**
- Select **Restart** instead of **Auto-logoff**
- Note your **Master Client ID**, **Host**, and **Port**

---

## 📚 Documentation

See the included Swift Playgrounds for:

- Real-time streaming
- Historical queries
- Order placement
- Market quote snapshots

---

## 📝 License

MIT. See [LICENSE](LICENSE).

---

## 🔗 Related

- [Interactive Brokers API Docs](https://interactivebrokers.github.io/tws-api/)
- [IB Gateway Download](https://www.interactivebrokers.com/en/trading/ibgateway-stable.php)


---

## 🙏 Acknowledgements

This project is a continuation and substantial evolution of the excellent work by [@stensoosaar](https://github.com/stensoosaar) in the original [IBKit](https://github.com/stensoosaar/IBKit) repository.

We deeply appreciate the solid foundation and effort that went into building the original Swift interface for Interactive Brokers. Much of the protocol groundwork and initial implementation has been carried forward, modernized, and extended for async/await, stream-based data handling, and Linux support.

If you find this fork useful, please consider also ⭐️ starring the original repo as a gesture of thanks.
