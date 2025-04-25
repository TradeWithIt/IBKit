//
//  IBOpenOrder.swift
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

public struct IBOpenOrder: IBResponse, IBIndexedEvent {
    public var requestID: Int {
        return order.orderID
    }

    public var order: IBOrder

    public init(from decoder: IBDecoder) throws {
        guard let serverVersion = decoder.serverVersion else {
            throw IBClientError.decodingError("Missing server version")
        }

        var container = try decoder.unkeyedContainer()
        // version
        let _ = serverVersion < IBServerVersion.ORDER_CONTAINER ? try container.decode(Int.self) : serverVersion
        order = try container.decode(IBOrder.self)
    }
}

public struct IBOpenOrderEnd: IBResponse, IBEvent {
    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
    }
}
