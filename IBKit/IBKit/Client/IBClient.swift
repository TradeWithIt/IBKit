//
//  IBClient.swift
//	IBKit
//
//	Copyright (c) 2016-2023 Sten Soosaar
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.
//

import Foundation
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix

open class IBClient: @unchecked Sendable, IBAnyClient, IBRequestWrapper {
    // MARK: - Async Event Feed

    private let requestLimiter = IBRequestLimiter()
    let broadcaster = EventBroadcaster<IBEvent>()
    
    public var eventFeed: AsyncStream<IBEvent> {
        get async {
            await broadcaster.stream()
        }
    }

    // MARK: - Properties

    var _serverVersion: Int?
    private var serverVersionContinuation: CheckedContinuation<Int, Never>?
    private var apiConnectedContinuation: CheckedContinuation<Void, Error>?

    public var serverVersion: Int? {
        get { _serverVersion }
        set { _serverVersion = newValue }
    }

    public var connectionTime: String?
    public var debugMode: Bool = false {
        willSet { connection?.debugMode = newValue }
    }

    public let id: Int
    public let host: String
    public let port: Int

    private var connection: IBConnection?
    var nextValidID: Int = 0

    public var nextRequestID: Int {
        let value = nextValidID
        nextValidID += 1
        return value
    }

    // MARK: - Init

    public init(id: Int, address: String, port: Int) {
        guard let host = URL(string: address)?.host else {
            fatalError("Invalid host URL")
        }
        self.id = id
        self.host = host
        self.port = port
    }

    // MARK: - Connection

    public func connect() async throws {
        guard connection == nil else {
            throw IBClientError.connectionError("Already connected")
        }

        let connection = try IBConnection(host: host, port: port)
        connection.stateDidChangeCallback = { [weak self] state in
            self?.stateDidChange(to: state)
        }
        connection.delegate = self
        connection.debugMode = debugMode
        self.connection = connection
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.apiConnectedContinuation = continuation
        }
    }

    public func disconnect() async {
        await broadcaster.finish()
        connection?.disconnect()
        connection = nil
    }

    // MARK: - Send Request

    func yield<T: IBEvent>(_ event: T) {
        Task {
            await broadcaster.yield(event)
        }
    }
    
    /// Sends a raw IB request to the broker.
    /// - Parameter request: The `IBRequest` to encode and dispatch.
    /// - Throws: `IBClientError.failedToSend` if the client is not connected or not ready.
    public func send(request: IBRequest) async throws {
        try await requestLimiter.waitIfNeeded(for: request.pacingType)
        try sendNow(request: request)
    }

    private func sendNow(request: IBRequest) throws {
        guard let connection, [.connected, .connectedToAPI].contains(connection.state) else {
            throw IBClientError.failedToSend("Client not connected")
        }

        let encoder = IBEncoder(_serverVersion)
        try encoder.encode(request)
        let data = encoder.data
        let dataWithLength = data.count.toBytes(size: 4) + data
        connection.send(data: dataWithLength)
    }

    /// Sends a request and returns an unfiltered event stream associated with this session.
    /// This guarantees a stream consumer is registered **before** sending the request,
    /// ensuring no events are dropped due to early delivery.
    /// - Parameter request: The request to send.
    /// - Returns: An `AsyncStream<IBEvent>` of incoming events.
    /// - Throws: `IBClientError.failedToSend` if the request could not be dispatched.
    public func stream<Event: IBEvent>(request: IBRequest) async throws -> AsyncStream<Event> {
        AsyncStream { continuation in
            Task {
                let stream = await broadcaster.stream()
                try await send(request: request)
                for await event in stream {
                    guard let event = event as? Event else { continue }
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    /// Sends an indexed request and returns a stream filtered by its `requestID`.
    /// Internally, ensures the stream is registered before dispatching the request,
    /// and yields only matching events from the shared event stream.
    /// - Parameter request: The indexed request (conforming to `IBIndexedRequest`) to send.
    /// - Returns: A filtered `AsyncStream<IBIndexedEvent>` scoped to the `requestID`.
    /// - Throws: `IBClientError.failedToSend` if the request could not be dispatched.
    public func stream<Event: IBIndexedEvent>(request: IBIndexedRequest) async throws -> AsyncStream<Event> {
        AsyncStream { continuation in
            Task {
                let stream = await broadcaster.stream()
                try await send(request: request)
                for await event in stream {
                    guard
                        let event = event as? Event,
                        event.requestID == request.requestID
                    else { continue }
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    // MARK: - State Change

    private func stateDidChange(to state: IBConnection.State) {
        if state == .connectedToAPI {
            Task { try? await self.startAPI() }
            apiConnectedContinuation?.resume()
            apiConnectedContinuation = nil
        }
    }

    private func startAPI() async throws {
        let encoder = IBEncoder()
        var container = encoder.unkeyedContainer()
        try container.encode(IBRequestType.startAPI)
        try container.encode(2) // API version
        try container.encode(id)
        try container.encode("") // Reserved
        let data = encoder.data
        let dataWithLength = data.count.toBytes(size: 4) + data
        connection?.send(data: dataWithLength)
    }

    // MARK: - Server Version Handling

    public func setServerVersion(_ version: Int) {
        _serverVersion = version
        serverVersionContinuation?.resume(returning: version)
        serverVersionContinuation = nil
    }

    // MARK: Types

    actor EventBroadcaster<T: Sendable> {
        private var continuations = [UUID: AsyncStream<T>.Continuation]()

        func stream() -> AsyncStream<T> {
            let id = UUID()
            return AsyncStream { continuation in
                continuations[id] = continuation

                continuation.onTermination = { @Sendable _ in
                    Task { [id] in await self.removeContinuation(id) }
                }
            }
        }

        func yield(_ event: T) {
            for continuation in continuations.values {
                continuation.yield(event)
            }
        }

        func finish() {
            for continuation in continuations.values {
                continuation.finish()
            }
            continuations.removeAll()
        }

        private func removeContinuation(_ id: UUID) {
            continuations.removeValue(forKey: id)
        }
    }
}

public extension IBClient {
    enum ConnectionType {
        case gateway
        case workstation

        var host: String {
            "https://127.0.0.1"
        }

        var liveTradingPort: Int {
            switch self {
            case .gateway: return 4001
            case .workstation: return 7496
            }
        }

        var simulatedTradingPort: Int {
            switch self {
            case .gateway: return 4002
            case .workstation: return 7497
            }
        }
    }

    /// Creates new live trading client. All orders you send to broker, will be real and executed.
    /// - Parameter id: Master API ID, set in IB Gateway or Workstation
    /// - Parameter type: Connection type you are using.

    static func live(id: Int, type: ConnectionType = .gateway) -> IBClient {
        IBClient(id: id, address: type.host, port: type.liveTradingPort)
    }

    /// Creates new paper trading client, with simulated orders.
    /// - Parameter id: Master API ID, set in IB Gateway or Workstation
    /// - Parameter type: Connection type you are using.

    static func paper(id: Int, type: ConnectionType = .gateway) -> IBClient {
        IBClient(id: id, address: type.host, port: type.simulatedTradingPort)
    }
}
