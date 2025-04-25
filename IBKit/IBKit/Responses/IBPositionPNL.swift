//
//  IBPositionPNL.swift
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

public struct IBPositionPNL: IBResponse, IBIndexedEvent {
    public var requestID: Int
    public var contractID: Int?
    public var account: String?
    public var position: Double
    public var daily: Double
    public var unrealized: Double
    public var realized: Double
    public var value: Double

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        requestID = try container.decode(Int.self)
        position = try container.decode(Double.self)
        daily = try container.decode(Double.self)
        unrealized = try container.decode(Double.self)
        realized = try container.decode(Double.self)
        value = try container.decode(Double.self)
    }
}
