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
    private struct QueuedRequest {
        let type: RequestType
        let requestID: Int?
        let continuation: CheckedContinuation<Void, Error>
    }

    private var queue: [QueuedRequest] = []
    private var requestTimestamps: [Date] = []
    private var contractDetailsTimestamps: [Date] = []
    private var openHistoricalRequests: Set<Int> = []

    private let maxRequestsPerSecond = 50
    private let maxContractDetailsPerWindow = 50
    private let contractDetailsWindow: TimeInterval = 600 // 10 min
    private let maxOpenHistoricalRequests = 100

    private let cooldownDuration: TimeInterval = 10
    private let interRequestDelay: TimeInterval = 0.02 // 20ms

    private var isCoolingDown = false
    private var isProcessing = false

    func waitIfNeeded(for type: RequestType, requestID: Int?) async throws {
        try await withCheckedThrowingContinuation { cont in
            queue.append(.init(type: type, requestID: requestID, continuation: cont))
            if !isProcessing {
                isProcessing = true
                Task { await self.processQueue() }
            }
        }
    }

    func markHistoricalRequestFinished(id: Int) {
        openHistoricalRequests.remove(id)
    }

    private func processQueue() async {
        while !queue.isEmpty {
            if isCoolingDown {
                await sleepCooldown()
            }

            let now = Date()
            requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < 1 }

            if requestTimestamps.count >= maxRequestsPerSecond {
                let delay = 1.0 - now.timeIntervalSince(requestTimestamps.first!)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }

            let request = queue.removeFirst()

            do {
                try enforceTypeSpecificLimit(for: request.type, id: request.requestID)
                requestTimestamps.append(Date())

                // Cooldown logic: trigger if usage is consistently maxed
                if requestTimestamps.count >= maxRequestsPerSecond - 1 {
                    isCoolingDown = true
                }

                request.continuation.resume()
            } catch {
                request.continuation.resume(throwing: error)
            }

            try? await Task.sleep(nanoseconds: UInt64(interRequestDelay * 1_000_000_000))
        }

        isProcessing = false
    }

    private func enforceTypeSpecificLimit(for type: RequestType, id: Int?) throws {
        let now = Date()

        switch type {
        case .contractDetails:
            contractDetailsTimestamps = contractDetailsTimestamps.filter { now.timeIntervalSince($0) < contractDetailsWindow }
            guard contractDetailsTimestamps.count < maxContractDetailsPerWindow else {
                throw IBClientError.pacingViolation("Too many contract details requests (50 per 10min)")
            }
            contractDetailsTimestamps.append(now)

        case .historicalData:
            guard openHistoricalRequests.count < maxOpenHistoricalRequests else {
                throw IBClientError.pacingViolation("Too many open historical data requests")
            }
            if let id = id {
                openHistoricalRequests.insert(id)
            }

        case .other:
            break
        }
    }

    private func sleepCooldown() async {
        do {
            try await Task.sleep(nanoseconds: UInt64(cooldownDuration * 1_000_000_000))
        } catch {
            // Ignore cancellation, just end cooldown
        }
        isCoolingDown = false
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
