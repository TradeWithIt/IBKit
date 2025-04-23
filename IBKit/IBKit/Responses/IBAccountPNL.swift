//
//  IBAccountPNL.swift
//
//
//  Created by Sten Soosaar on 21.10.2023.
//

import Foundation

public struct IBAccountPNL: IBResponse, IBIndexedEvent {
    public var requestID: Int
    public var daily: Double
    public var unrealized: Double
    public var realized: Double

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        requestID = try container.decode(Int.self)
        daily = try container.decode(Double.self)
        unrealized = try container.decode(Double.self)
        realized = try container.decode(Double.self)
    }
}
