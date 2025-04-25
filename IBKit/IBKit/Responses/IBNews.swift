//
//  IBNews.swift
//
//
//  Created by Sten Soosaar on 21.10.2023.
//

import Foundation

public struct IBNews: IBResponse, IBEvent {
    public var tickerID: Int
    public var date: Date
    public var providerCode: String
    public var articleId: String
    public var headline: String
    public var extraData: String

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        tickerID = try container.decode(Int.self)
        date = try container.decode(Date.self)
        providerCode = try container.decode(String.self)
        articleId = try container.decode(String.self)
        headline = try container.decode(String.self)
        extraData = try container.decode(String.self)
    }
}
