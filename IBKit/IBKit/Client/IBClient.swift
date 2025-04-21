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
import NIOCore
import NIOConcurrencyHelpers
import NIOPosix

open class IBClient: IBAnyClient, IBRequestWrapper {
    
    // MARK: - Async Event Feed
    
    public var eventContinuation: AsyncStream<IBEvent>.Continuation!
    
    public private(set) lazy var eventFeed: AsyncStream<IBEvent> = {
        AsyncStream { continuation in
            self.eventContinuation = continuation
        }
    }()
    
    // MARK: - Properties
    
    var _serverVersion: Int?
    private var serverVersionContinuation: CheckedContinuation<Int, Never>?

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

    public func connect() throws {
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
    }

    public func disconnect() {
        connection?.disconnect()
        connection = nil
        eventContinuation?.finish()
    }

    // MARK: - Send Request

    public func send(request: IBRequest) throws {
        guard let connection, [.connected, .connectedToAPI].contains(connection.state) else {
            throw IBClientError.failedToSend("Client not connected")
        }

        let encoder = IBEncoder(_serverVersion)
        try encoder.encode(request)
        let data = encoder.data
        let dataWithLength = data.count.toBytes(size: 4) + data
        connection.send(data: dataWithLength)
    }

    // MARK: - State Change

    private func stateDidChange(to state: IBConnection.State) {
        if state == .connectedToAPI {
            Task { try? await self.startAPI() }
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
}

public extension IBClient {
	enum ConnectionType {
		case gateway
		case workstation
		
		internal var host: String {
			"https://127.0.0.1"
		}
		
		internal var liveTradingPort: Int {
			switch self{
				case .gateway:        return 4001
				case .workstation:    return 7496
			}
		}
		
		internal var simulatedTradingPort: Int {
			switch self{
				case .gateway:        return 4002
				case .workstation:    return 7497
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
