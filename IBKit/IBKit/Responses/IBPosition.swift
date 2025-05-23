//
//  IBPosition.swift
//
//
//  Created by Sten Soosaar on 21.10.2023.
//

import Foundation

public struct IBPosition: IBResponse, IBEvent {
    public var accountName: String
    public var contract: IBContract
    public var position: Double = 0
    public var avgCost: Double = 0

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
        accountName = try container.decode(String.self)
        contract = try container.decode(IBContract.self)
        position = try container.decode(Double.self)
        avgCost = try container.decode(Double.self)
    }
}

public struct IBPositionEnd: IBResponse, IBEvent {
    public var requestID: Int

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        requestID = try container.decode(Int.self)
    }
}

public struct IBPositionMulti: IBResponse, IBIndexedEvent {
    public var requestID: Int
    public var account: String
    public var modelCode: String
    public var contract: IBContract
    public var position: Double
    public var avgCost: Double

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
        requestID = try container.decode(Int.self)
        account = try container.decode(String.self)
        contract = try container.decode(IBContract.self)
        position = try container.decode(Double.self)
        avgCost = try container.decode(Double.self)
        modelCode = try container.decode(String.self)
    }
}

public struct IBPositionMultiEnd: IBResponse, IBIndexedEvent {
    public var requestID: Int

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
        requestID = try container.decode(Int.self)
    }
}
