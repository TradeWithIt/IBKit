//
//  IBClient.swift
//    IBKit
//
//    Copyright (c) 2016-2023 Szymon Lorenz
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import Foundation

actor IBRequestLimiter {
    private var requestTimestamps: [Date] = []
    private var contractDetailsTimestamps: [Date] = []
    private var openHistoricalRequests: Set<Int> = []

    private let maxRequestsPerSecond = 50
    private let maxBurstDuration: TimeInterval = 60.0
    private let cooldownDuration: TimeInterval = 10.0
    private let contractDetailsWindow: TimeInterval = 600 // 10 minutes
    private let maxContractDetailsPerWindow = 50
    private let maxOpenHistoricalRequests = 100

    private var requestStartTime: Date?
    private var isCoolingDown = false

    func waitIfNeeded(for type: RequestType, requestID: Int? = nil) async throws {
        let now = Date()

        // General burst pacing
        if isCoolingDown {
            try await sleepCooldown()
        }

        if requestStartTime == nil {
            requestStartTime = now
        }

        if let start = requestStartTime, now.timeIntervalSince(start) > maxBurstDuration {
            try await sleepCooldown()
        }

        // Enforce 50 requests/second
        requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < 1 }
        if requestTimestamps.count >= maxRequestsPerSecond {
            let sleepTime = 1.0 - now.timeIntervalSince(requestTimestamps.first!)
            try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
        }

        requestTimestamps.append(now)

        // Type-specific pacing
        switch type {
        case .contractDetails:
            contractDetailsTimestamps = contractDetailsTimestamps.filter { now.timeIntervalSince($0) < contractDetailsWindow }
            guard contractDetailsTimestamps.count < maxContractDetailsPerWindow else {
                throw IBClientError.pacingViolation("Too many contract details requests (50 per 10min)")
            }
            contractDetailsTimestamps.append(now)

        case .historicalData:
            guard openHistoricalRequests.count < maxOpenHistoricalRequests else {
                throw IBClientError.pacingViolation("Max 100 open historical data requests")
            }
            if let id = requestID {
                openHistoricalRequests.insert(id)
            }

        case .other:
            break
        }
    }

    func markHistoricalRequestFinished(id: Int) {
        openHistoricalRequests.remove(id)
    }

    private func sleepCooldown() async throws {
        isCoolingDown = true
        try await Task.sleep(nanoseconds: UInt64(cooldownDuration * 1_000_000_000))
        isCoolingDown = false
        requestStartTime = nil
        requestTimestamps.removeAll()
    }

    enum RequestType {
        case contractDetails
        case historicalData
        case other
    }
}

extension IBRequest {
    var pacingType: IBRequestLimiter.RequestType {
        switch type {
        case .contractData:
            return .contractDetails
        case .historicalData:
            return .historicalData
        default:
            return .other
        }
    }
}
