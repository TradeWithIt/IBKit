//
//  IBClient+Connection.swift
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
    func connection(_: IBConnection, didConnect date: String, toServer version: Int) {
        connectionTime = date
        setServerVersion(version)
    }

    func connection(_: IBConnection, didStopCallback _: Error?) {
        Task {
            await broadcaster.finish()
        }
    }

    func connection(_: IBConnection, didReceiveData data: Data) {
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
                try yield(decoder.decode(IBServerError.self))

            case .NEXT_VALID_ID:
                let object = try decoder.decode(IBNextRequestID.self)
                nextValidID = object.value

            case .CURRENT_TIME:
                try yield(decoder.decode(IBServerTime.self))

            case .ACCT_VALUE:
                try yield(decoder.decode(IBAccountUpdate.self))

            case .ACCT_UPDATE_TIME:
                try yield(decoder.decode(IBAccountUpdateTime.self))

            case .PORTFOLIO_VALUE:
                try yield(decoder.decode(IBPortfolioValue.self))

            case .ACCT_DOWNLOAD_END:
                try yield(decoder.decode(IBAccountUpdateEnd.self))

            case .SYMBOL_SAMPLES:
                try yield(decoder.decode(IBContractSearchResult.self))

            case .MANAGED_ACCTS:
                try yield(decoder.decode(IBManagedAccounts.self))

            case .PNL:
                try yield(decoder.decode(IBAccountPNL.self))

            case .ACCOUNT_SUMMARY:
                try yield(decoder.decode(IBAccountSummary.self))

            case .ACCOUNT_SUMMARY_END:
                try yield(decoder.decode(IBAccountSummaryEnd.self))

            case .ACCOUNT_UPDATE_MULTI:
                try yield(decoder.decode(IBAccountSummaryMulti.self))

            case .ACCOUNT_UPDATE_MULTI_END:
                try yield(decoder.decode(IBAccountSummaryMultiEnd.self))

            case .POSITION_DATA:
                try yield(decoder.decode(IBPosition.self))

            case .POSITION_END:
                try yield(decoder.decode(IBPositionEnd.self))

            case .PNL_SINGLE:
                try yield(decoder.decode(IBPositionPNL.self))

            case .POSITION_MULTI:
                try yield(decoder.decode(IBPositionMulti.self))

            case .POSITION_MULTI_END:
                try yield(decoder.decode(IBPositionMultiEnd.self))

            case .OPEN_ORDER:
                try yield(decoder.decode(IBOpenOrder.self))

            case .OPEN_ORDER_END:
                try yield(decoder.decode(IBOpenOrderEnd.self))

            case .ORDER_STATUS:
                try yield(decoder.decode(IBOrderStatus.self))

            case .COMPLETED_ORDER:
                try yield(decoder.decode(IBOrderCompletion.self))

            case .COMPLETED_ORDERS_END:
                try yield(decoder.decode(IBOrderCompetionEnd.self))

            case .EXECUTION_DATA:
                try yield(decoder.decode(IBOrderExecution.self))

            case .EXECUTION_DATA_END:
                try yield(decoder.decode(IBOrderExecutionEnd.self))

            case .COMMISSION_REPORT:
                try yield(decoder.decode(IBCommissionReport.self))

            case .CONTRACT_DATA:
                try yield(decoder.decode(IBContractDetails.self))

            case .CONTRACT_DATA_END:
                try yield(decoder.decode(IBContractDetailsEnd.self))

            case .SECURITY_DEFINITION_OPTION_PARAMETER:
                try yield(decoder.decode(IBOptionChain.self))

            case .SECURITY_DEFINITION_OPTION_PARAMETER_END:
                try yield(decoder.decode(IBOptionChainEnd.self))

            case .FUNDAMENTAL_DATA:
                try yield(decoder.decode(IBFinancialReport.self))

            case .HEAD_TIMESTAMP:
                try yield(decoder.decode(IBHeadTimestamp.self))

            case .HISTORICAL_DATA:
                try yield(decoder.decode(IBPriceHistory.self))

            case .HISTORICAL_DATA_UPDATE:
                let response = try decoder.decode(IBPriceBarHistoryUpdate.self)
                yield(IBPriceBarUpdate(requestID: response.requestID, bar: response.bar))

            case .REAL_TIME_BARS:
                try yield(decoder.decode(IBPriceBarUpdate.self))

            case .MARKET_RULE:
                try yield(decoder.decode(IBMarketRule.self))

            case .MARKET_DATA_TYPE:
                try yield(decoder.decode(IBCurrentMarketDataType.self))

            case .TICK_REQ_PARAMS:
                _ = try decoder.decode(IBTickParameters.self) // not yielded yet

            case .NEWS_BULLETINS:
                try yield(decoder.decode(IBNewsBulletin.self))

            case .MARKET_DEPTH:
                try yield(decoder.decode(IBMarketDepth.self))

            case .MARKET_DEPTH_L2:
                try yield(decoder.decode(IBMarketDepthLevel2.self))

            case .TICK_PRICE:
                let message = try decoder.decode(IBTickPrice.self)
                message.tick.forEach { yield($0) }

            case .TICK_SIZE:
                let message = try decoder.decode(IBTickSize.self)
                yield(message.tick)

            case .TICK_GENERIC:
                let message = try decoder.decode(IBTickGeneric.self)
                yield(message.tick)

            case .TICK_STRING:
                let message = try decoder.decode(IBTickString.self)
                yield(message.tick)

            case .HISTORICAL_TICKS:
                let message = try decoder.decode(IBHistoricTick.self)
                message.ticks.forEach { yield($0) }

            case .HISTORICAL_TICKS_BID_ASK:
                let message = try decoder.decode(IBHistoricalTickBidAsk.self)
                message.ticks.forEach { yield($0) }

            case .HISTORICAL_TICKS_LAST:
                let message = try decoder.decode(IBHistoricalTickLast.self)
                message.ticks.forEach { yield($0) }

            case .TICK_BY_TICK:
                let message = try decoder.decode(IBTickByTick.self)
                message.ticks.forEach { yield($0) }

            case .TICK_EFP:
                try yield(decoder.decode(IBEFPEvent.self))

            case .TICK_OPTION_COMPUTATION:
                try yield(decoder.decode(IBOptionComputation.self))

            case .HISTORICAL_NEWS:
                try yield(decoder.decode(IBHistoricalNews.self))

            case .HISTORICAL_NEWS_END:
                try yield(decoder.decode(IBHistoricalNewsEnd.self))

            case .SCANNER_PARAMETERS:
                try yield(decoder.decode(IBScannerParameters.self))

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
        case 2100 ... 2169:
            print("⚠️ warning: \(error.code) \(error.message)")
        case 501 ... 504:
            print("❌ client error: \(error.code) \(error.message)")
        case 100 ... 449, 10000 ... 10284:
            print("❌ tws error: \(error.code) \(error.message)")
            yield(error)
        default:
            print("❌ unknown error: \(error.code) \(error.message)")
        }
    }
}
