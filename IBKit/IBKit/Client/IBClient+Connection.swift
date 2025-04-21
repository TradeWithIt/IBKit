//
//  IBClient+ConnectionDelegate.swift
// 	IBKit
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


extension IBClient: IBConnectionDelegate {

    func connection(_ connection: IBConnection, didConnect date: String, toServer version: Int) {
        self.connectionTime = date
        self.setServerVersion(version)
    }

    func connection(_ connection: IBConnection, didStopCallback error: Error?) {
        eventContinuation?.finish()
    }

    func connection(_ connection: IBConnection, didReceiveData data: Data) {
        if debugMode {
            print("\(Date()) -> \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")")
        }

        do {
            let decoder = IBDecoder(serverVersion)
            let responseValue = try decoder.decode(Int.self, from: data)
            guard let responseType = IBResponseType(rawValue: responseValue) else {
                print("Unknown response: \(responseValue)")
                return
            }

            switch responseType {
                // MARK: - Example Cases
            case .ERR_MSG:
                try eventContinuation?.yield(decoder.decode(IBServerError.self))

            case .NEXT_VALID_ID:
                let object = try decoder.decode(IBNextRequestID.self)
                nextValidID = object.value

            case .CURRENT_TIME:
                try eventContinuation?.yield(decoder.decode(IBServerTime.self))

            case .ACCT_VALUE:
                try eventContinuation?.yield(decoder.decode(IBAccountUpdate.self))

            case .ACCT_UPDATE_TIME:
                try eventContinuation?.yield(decoder.decode(IBAccountUpdateTime.self))

            case .PORTFOLIO_VALUE:
                try eventContinuation?.yield(decoder.decode(IBPortfolioValue.self))

            case .ACCT_DOWNLOAD_END:
                try eventContinuation?.yield(decoder.decode(IBAccountUpdateEnd.self))

            case .SYMBOL_SAMPLES:
                try eventContinuation?.yield(decoder.decode(IBContractSearchResult.self))

            case .MANAGED_ACCTS:
                try eventContinuation?.yield(decoder.decode(IBManagedAccounts.self))

            case .PNL:
                try eventContinuation?.yield(decoder.decode(IBAccountPNL.self))

            case .ACCOUNT_SUMMARY:
                try eventContinuation?.yield(decoder.decode(IBAccountSummary.self))

            case .ACCOUNT_SUMMARY_END:
                try eventContinuation?.yield(decoder.decode(IBAccountSummaryEnd.self))

            case .ACCOUNT_UPDATE_MULTI:
                try eventContinuation?.yield(decoder.decode(IBAccountSummaryMulti.self))

            case .ACCOUNT_UPDATE_MULTI_END:
                try eventContinuation?.yield(decoder.decode(IBAccountSummaryMultiEnd.self))

            case .POSITION_DATA:
                try eventContinuation?.yield(decoder.decode(IBPosition.self))

            case .POSITION_END:
                try eventContinuation?.yield(decoder.decode(IBPositionEnd.self))

            case .PNL_SINGLE:
                try eventContinuation?.yield(decoder.decode(IBPositionPNL.self))

            case .POSITION_MULTI:
                try eventContinuation?.yield(decoder.decode(IBPositionMulti.self))

            case .POSITION_MULTI_END:
                try eventContinuation?.yield(decoder.decode(IBPositionMultiEnd.self))

            case .OPEN_ORDER:
                try eventContinuation?.yield(decoder.decode(IBOpenOrder.self))

            case .OPEN_ORDER_END:
                try eventContinuation?.yield(decoder.decode(IBOpenOrderEnd.self))

            case .ORDER_STATUS:
                try eventContinuation?.yield(decoder.decode(IBOrderStatus.self))

            case .COMPLETED_ORDER:
                try eventContinuation?.yield(decoder.decode(IBOrderCompletion.self))

            case .COMPLETED_ORDERS_END:
                try eventContinuation?.yield(decoder.decode(IBOrderCompetionEnd.self))

            case .EXECUTION_DATA:
                try eventContinuation?.yield(decoder.decode(IBOrderExecution.self))

            case .EXECUTION_DATA_END:
                try eventContinuation?.yield(decoder.decode(IBOrderExecutionEnd.self))

            case .COMMISSION_REPORT:
                try eventContinuation?.yield(decoder.decode(IBCommissionReport.self))

            case .CONTRACT_DATA:
                try eventContinuation?.yield(decoder.decode(IBContractDetails.self))

            case .CONTRACT_DATA_END:
                try eventContinuation?.yield(decoder.decode(IBContractDetailsEnd.self))

            case .SECURITY_DEFINITION_OPTION_PARAMETER:
                try eventContinuation?.yield(decoder.decode(IBOptionChain.self))

            case .SECURITY_DEFINITION_OPTION_PARAMETER_END:
                try eventContinuation?.yield(decoder.decode(IBOptionChainEnd.self))

            case .FUNDAMENTAL_DATA:
                try eventContinuation?.yield(decoder.decode(IBFinancialReport.self))

            case .HEAD_TIMESTAMP:
                try eventContinuation?.yield(decoder.decode(IBHeadTimestamp.self))

            case .HISTORICAL_DATA:
                try eventContinuation?.yield(decoder.decode(IBPriceHistory.self))

            case .HISTORICAL_DATA_UPDATE:
                let response = try decoder.decode(IBPriceBarHistoryUpdate.self)
                eventContinuation?.yield(IBPriceBarUpdate(requestID: response.requestID, bar: response.bar))

            case .REAL_TIME_BARS:
                try eventContinuation?.yield(decoder.decode(IBPriceBarUpdate.self))

            case .MARKET_RULE:
                try eventContinuation?.yield(decoder.decode(IBMarketRule.self))

            case .MARKET_DATA_TYPE:
                try eventContinuation?.yield(decoder.decode(IBCurrentMarketDataType.self))

            case .TICK_REQ_PARAMS:
                _ = try decoder.decode(IBTickParameters.self) // not yielded yet

            case .NEWS_BULLETINS:
                try eventContinuation?.yield(decoder.decode(IBNewsBulletin.self))

            case .MARKET_DEPTH:
                try eventContinuation?.yield(decoder.decode(IBMarketDepth.self))

            case .MARKET_DEPTH_L2:
                try eventContinuation?.yield(decoder.decode(IBMarketDepthLevel2.self))

            case .TICK_PRICE:
                let message = try decoder.decode(IBTickPrice.self)
                message.tick.forEach { eventContinuation?.yield($0) }

            case .TICK_SIZE:
                let message = try decoder.decode(IBTickSize.self)
                eventContinuation?.yield(message.tick)

            case .TICK_GENERIC:
                let message = try decoder.decode(IBTickGeneric.self)
                eventContinuation?.yield(message.tick)

            case .TICK_STRING:
                let message = try decoder.decode(IBTickString.self)
                eventContinuation?.yield(message.tick)

            case .HISTORICAL_TICKS:
                let message = try decoder.decode(IBHistoricTick.self)
                message.ticks.forEach { eventContinuation?.yield($0) }

            case .HISTORICAL_TICKS_BID_ASK:
                let message = try decoder.decode(IBHistoricalTickBidAsk.self)
                message.ticks.forEach { eventContinuation?.yield($0) }

            case .HISTORICAL_TICKS_LAST:
                let message = try decoder.decode(IBHistoricalTickLast.self)
                message.ticks.forEach { eventContinuation?.yield($0) }

            case .TICK_BY_TICK:
                let message = try decoder.decode(IBTickByTick.self)
                message.ticks.forEach { eventContinuation?.yield($0) }

            case .TICK_EFP:
                try eventContinuation?.yield(decoder.decode(IBEFPEvent.self))

            case .TICK_OPTION_COMPUTATION:
                try eventContinuation?.yield(decoder.decode(IBOptionComputation.self))

            case .HISTORICAL_NEWS:
                try eventContinuation?.yield(decoder.decode(IBHistoricalNews.self))

            case .HISTORICAL_NEWS_END:
                try eventContinuation?.yield(decoder.decode(IBHistoricalNewsEnd.self))

            case .SCANNER_PARAMETERS:
                try eventContinuation?.yield(decoder.decode(IBScannerParameters.self))

            default:
                print("⚠️ Unknown response type: \(responseType)")
            }

        } catch {
            print("❌ Decode error: \(error.localizedDescription)")
        }
    }

    func dispatchError(_ error: IBServerError) {
        switch error.code {
        case 1100, 1101, 1102, 1300:
            print("⚠️ connectivity error: \(error.code) \(error.message)")
        case 2100...2169:
            print("⚠️ warning: \(error.code) \(error.message)")
        case 501...504:
            print("❌ client error: \(error.code) \(error.message)")
        case 100...449, 10000...10284:
            print("❌ tws error: \(error.code) \(error.message)")
            eventContinuation?.yield(error)
        default:
            print("❌ unknown error: \(error.code) \(error.message)")
        }
    }
}
