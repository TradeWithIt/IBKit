//
//  DateInterval+Ext.swift
//
//
//  Created by Sten Soosaar on 20.04.2024.
//

import Foundation

public extension DateInterval {
    static func lookback(_ value: Int, unit: Calendar.Component, until endDate: Date = Date()) -> DateInterval {
        let adjustedEnd = endDate.timeIntervalSince1970 > Date().timeIntervalSince1970 ? Date() : endDate
        let startDate = Calendar.current.date(byAdding: unit, value: -1 * abs(value), to: adjustedEnd)!
        return DateInterval(start: startDate, end: endDate)
    }

    func contains(date: Date?) -> Bool {
        guard let date = date else { return false }
        return contains(date)
    }

    func strideThrough(by timeInterval: TimeInterval) -> StrideThrough<TimeInterval> {
        return stride(
            from: start.timeIntervalSince1970,
            through: end.timeIntervalSince1970,
            by: timeInterval
        )
    }

    func strideTo(by timeInterval: TimeInterval) -> StrideTo<TimeInterval> {
        return stride(
            from: start.timeIntervalSince1970,
            to: end.timeIntervalSince1970,
            by: timeInterval
        )
    }

    var twsDescription: String {
        let adjustedEnd = end.timeIntervalSince1970 > Date().timeIntervalSince1970 ? Date() : end
        let adjustedDuration = adjustedEnd.timeIntervalSince1970 - start.timeIntervalSince1970

        switch adjustedDuration {
        case 0 ..< 86400:
            return String(format: "%d S", Int(adjustedDuration))
        case 86400 ..< 2_678_400:
            return String(format: "%d D", Int(adjustedDuration / 86400))
        case 2_678_400 ..< 31_536_000:
            return String(format: "%d M", Int(adjustedDuration / 2_678_400))
        default:
            return String(format: "%d Y", Int(adjustedDuration / 31_536_000))
        }
    }
}
