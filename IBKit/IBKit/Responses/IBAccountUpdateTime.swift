//
//  IBAccountUpdateTime.swift
//
//
//  Created by Sten Soosaar on 29.10.2023.
//

import Foundation

public struct IBAccountUpdateTime: IBResponse, IBEvent {
    public var timmestamp: Date

    public init(from decoder: IBDecoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int.self)
        let timeString = try container.decode(String.self)
        let components = timeString.components(separatedBy: ":")

        guard let minuteString = components.first, let minutes = Double(minuteString),
              let secondsString = components.last, let seconds = Double(secondsString)
        else {
            throw IBClientError.decodingError("Unable to parse account update time")
        }

        timmestamp = Date().startOfDay.addingTimeInterval(minutes * 60 + seconds)
    }
}
