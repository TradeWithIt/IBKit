//
//  IBEFPEvent.swift
//
//
//  Created by Sten Soosaar on 21.10.2023.
//

import Foundation

/// Exchange of physicals
///
/// A private agreement between two parties allowing for one party to swap a futures contract for the actual underlying asse

struct IBEFPEvent: IBResponse, IBIndexedEvent {
    public var requestID: Int

    public var type: IBTickType

    public var points: Double

    public var pointsFormatted: String

    public var impliedPrice: Double

    public var holded: Int

    public var futureLastTradeDate: Date

    public var dividendImpact: Double

    public var dividendsToLastTradeDate: Double

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
        requestID = try container.decode(Int.self)
        type = try container.decode(IBTickType.self)
        points = try container.decode(Double.self)
        pointsFormatted = try container.decode(String.self)
        impliedPrice = try container.decode(Double.self)
        holded = try container.decode(Int.self)
        futureLastTradeDate = try container.decode(Date.self)
        dividendImpact = try container.decode(Double.self)
        dividendsToLastTradeDate = try container.decode(Double.self)
    }
}
