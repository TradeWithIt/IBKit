//
//  IBAnyClient.swift
//
//
//  Created by Sten Soosaar on 11.05.2024.
//

import Foundation

public protocol IBAnyClient {
    var serverVersion: Int? { get set }

    func connect() async throws
    func disconnect() async

    /// Sends a raw IB request to the broker.
    /// - Parameter request: The `IBRequest` to encode and dispatch.
    /// - Throws: `IBClientError.failedToSend` if the client is not connected or not ready.
    func send(request: IBRequest) async throws

    /// Sends a request and returns an unfiltered event stream associated with this session.
    /// This guarantees a stream consumer is registered **before** sending the request,
    /// ensuring no events are dropped due to early delivery.
    /// - Parameter request: The request to send.
    /// - Returns: An `AsyncStream<IBEvent>` of incoming events.
    /// - Throws: `IBClientError.failedToSend` if the request could not be dispatched.
    func stream<Event: IBEvent>(request: IBRequest) async throws -> AsyncStream<Event>

    /// Sends an indexed request and returns a stream filtered by its `requestID`.
    /// Internally, ensures the stream is registered before dispatching the request,
    /// and yields only matching events from the shared event stream.
    /// - Parameter request: The indexed request (conforming to `IBIndexedRequest`) to send.
    /// - Returns: A filtered `AsyncStream<IBIndexedEvent>` scoped to the `requestID`.
    /// - Throws: `IBClientError.failedToSend` if the request could not be dispatched.
    func stream<Event: IBIndexedEvent>(request: IBIndexedRequest) async throws -> AsyncStream<Event>
}

public protocol IBRequestWrapper {
    func requestNextRequestID() async throws

    func requestServerTime() async throws

    func requestBulletins(includePast all: Bool) async throws

    func cancelNewsBulletins() async throws

    func setMarketDataType(_ type: IBMarketDataType) async throws

    func requestScannerParameters() async throws

    /// Requests account identifiers

    func requestManagedAccounts() async throws

    /// Subscribe account values, portfolio and last update time information
    /// - Parameter accountName: account name
    /// - Parameter subscribe: true for start and false to end
    func subscribeAccountUpdates(accountName: String, subscribe: Bool) async throws

    /// Subscribes account summary.
    /// - Parameter requestID: unique request identifier. Best way to obtain one, is by calling client.getNextID().
    /// - Parameter tags: Array of IBAccountKeys to specify what to subscribe. As a default, all keys will be subscribed
    /// - Parameter accountGroup:
    /// - Returns: AccountSummary event per specified tag and will be updated once per 3 minutes
    func subscribeAccountSummary(_ requestID: Int, tags: [IBAccountKey], accountGroup group: String) async throws

    /// Unsubscribes account summary
    /// - Parameter requestID: 	unique request identifier. Best way to obtain one, is by calling client.getNextID().
    /// - Returns: AccountSummaryEnd event
    func unsubscribeAccountSummary(_ requestID: Int) async throws

    /// Subscribes account summary.
    /// - Parameter requestID: unique request identifier. Best way to obtain one, is by calling client.getNextID().
    /// - Parameter tags: Array of IBAccountKeys to specify what to subscribe. As a default, all keys will be subscribed
    /// - Parameter accountGroup:
    /// - Returns: AccountSummary event per specified tag and will be updated once per 3 minutes
    func subscribeAccountSummaryMulti(_ requestID: Int, accountName: String, ledger: Bool, modelCode: String?) async throws

    /// Unsubscribes account summary
    /// - Parameter requestID: 	unique request identifier. Best way to obtain one, is by calling client.getNextID().
    /// - Returns: AccountSummaryEnd event
    func unsubscribeAccountSummaryMulti(_ requestID: Int) async throws

    /// Subscribes account profit and loss reporting
    /// - Parameter requestID: unique request identifier. Best way to obtain one, is by calling client.getNextID().
    /// - Parameter account: account identifier.
    /// - Parameter modelCode:
    /// - Returns: AccountPNL event
    func subscribeAccountPNL(_ requestID: Int, account: String, modelCode: [String]?) async throws

    /// Unsubscribes account profit and loss reporting
    /// - Parameter requestIDunique request identifier. Best way to obtain one, is by calling client.getNextID().
    func unsubscribeAccountPNL(_ requestID: Int) async throws

    func requestMarketRule(_ requestID: Int) async throws

    /// Requests first datapoint date for specific dataset
    /// - Parameter reqId: request ID
    /// - Parameter contract: contract description
    /// - Parameter barSource: data type to build a bar
    /// - Parameter extendedTrading: use only data from regular trading hours
    /// - Returns: FirstDatapoint event
    func firstDatapointDate(_ requestID: Int, contract: IBContract, barSource: IBBarSource, extendedTrading: Bool)
    async throws

    /// Requests first datapoint date for specific dataset
    /// - Parameter reqId: request ID
    /// - Parameter contract: contract description
    /// - Parameter barSize: what resolution one bar should be
    /// - Parameter barSource: data type to build a bar
    /// - Parameter lookback: date interval of request.
    /// - Parameter extendedTrading: shall data from extended trading hours be included or not
    /// - Returns: PriceHistory event. If IBDuration continousUpdates selected, also PriceBar event of requested resolution will be included as they occur

    func requestPriceHistory(
        _ requestID: Int,
        contract: IBContract,
        barSize size: IBBarSize,
        barSource: IBBarSource,
        lookback: DateInterval,
        extendedTrading: Bool,
        includeExpired: Bool
    ) async throws

    func subscribeRealTimeBar(
        _ requestID: Int,
        contract: IBContract,
        barSize size: IBBarSize,
        barSource: IBBarSource,
        extendedTrading: Bool
    ) async throws

    func requestMarketData(
        _ requestID: Int,
        contract: IBContract,
        events: [IBMarketDataRequest.SubscriptionType],
        snapshot: Bool,
        regulatory: Bool
    ) async throws

    /// subscribes live quote events including bid / ask / last trade and respective sizes
    /// - Parameter reqId:
    /// - Parameter contract:
    /// - Parameter snapshot:
    /// - Parameter regulatory:

    func subscribeMarketData(_ requestID: Int, contract: IBContract, snapshot: Bool, regulatory: Bool) async throws

    func unsubscribeMarketData(_ requestID: Int) async throws

    func subscribeMarketDepth(_ requestID: Int, contract: IBContract, rows: Int, smart: Bool) async throws

    func unsubscribeMarketDepth(_ requestID: Int) async throws

    func requestTickByTick(
        _ requestID: Int,
        contract: IBContract,
        tickType: IBTickRequest.TickType,
        tickCount: Int,
        ignoreSize: Bool
    ) async throws

    func cancelTickByTickData(_ requestID: Int) async throws

    /// High Resolution Historical Data
    /// - Parameter requestId: id of the request
    /// - Parameter contract: Contract object that is subject of query.
    /// - Parameter numberOfTicks, Number of distinct data points. Max is 1000 per request.
    /// - Parameter fromDate: requested period's starttime
    /// - Parameter whatToShow, (Bid_Ask, Midpoint, or Trades) Type of data requested.
    /// - Parameter useRth, Data from regular trading hours (1), or all available hours (0).
    /// - Parameter ignoreSize: Omit updates that reflect only changes in size, and not price. Applicable to Bid_Ask data requests.

    func historicalTicks(
        _ requestID: Int,
        contract: IBContract,
        numberOfTicks: Int,
        interval: DateInterval,
        whatToShow: IBTickHistoryRequest.TickSource,
        useRth: Bool,
        ignoreSize: Bool
    ) async throws

    func subscribePositions() async throws

    func unsubscribePositions() async throws

    func subscribePositionsMulti(_ requestID: Int, accountName: String, modelCode: String) async throws

    func unsubscribePositionsMulti(_ requestID: Int) async throws

    func subscribePositionPNL(_ requestID: Int, accountName: String, contractID: Int, modelCode: [String]) async throws

    func cancelAllOrders() async throws

    func cancelOrder(_ requestID: Int) async throws

    func requestExecutions(
        _ requestID: Int,
        clientID: Int?,
        accountName: String?,
        date: Date?,
        symbol: String?,
        securityType type: IBSecuritiesType?,
        market: IBExchange?,
        side: IBAction?
    ) async throws

    func requestOpenOrders() async throws

    func requestAllOpenOrders() async throws

    func requestAllOpenOrders(autoBind: Bool) async throws

    func requestCompletedOrders(apiOnly: Bool) async throws

    func placeOrder(_ requestID: Int, order: IBOrder) async throws

    func subscribeNews(_ requestID: Int, contract: IBContract, snapshot: Bool, regulatory: Bool) async throws

    func searchSymbols(_ requestID: Int, nameOrSymbol text: String) async throws

    func contractDetails(_ requestID: Int, contract: IBContract) async throws

    func subscribeFundamentals(_ requestID: Int, contract: IBContract, reportType: IBFundamantalsRequest.ReportType)
    async throws

    func unsubscribeFundamentals(_ requestID: Int) async throws

    /// Requests security definition option parameters for viewing a contract's option chain.
    /// - Parameters:
    /// - requestID: request index
    /// - underlying: underlying contract. symbol, type and contractID are required
    /// - exchange: exhange where options are traded. leaving empty will return all exchanges.

    func optionChain(_ requestID: Int, underlying contract: IBContract, exchange: IBExchange) async throws
}

public extension IBRequestWrapper where Self: IBAnyClient {
    func subscribePositionPNL(_ requestID: Int, accountName: String, contractID: Int, modelCode: [String] = [])
    async throws
    {
        let request = IBPositionPNLRequest(
            requestID: requestID,
            accountName: accountName,
            contractID: contractID,
            modelCode: modelCode
        )
        try await send(request: request)
    }

    func optionChain(_ requestID: Int, underlying contract: IBContract, exchange: IBExchange) async throws {
        let request = IBOptionChainRequest(requestID: requestID, underlying: contract, exchange: exchange)
        try await send(request: request)
    }

    func requestNextRequestID() async throws {
        let request = IBNextIDRquest()
        try await send(request: request)
    }

    func requestServerTime() async throws {
        let request = IBServerTimeRequest()
        try await send(request: request)
    }

    func requestBulletins(includePast all: Bool = false) async throws {
        let request = IBBulletinBoardRequest(includePast: all)
        try await send(request: request)
    }

    func cancelNewsBulletins() async throws {
        let request = IBBulletinBoardCancellationRequest()
        try await send(request: request)
    }

    func setMarketDataType(_ type: IBMarketDataType) async throws {
        let request = IBMarketDataTypeRequest(type)
        try await send(request: request)
    }

    func requestScannerParameters() async throws {
        let request = IBScannerParametersRequest()
        try await send(request: request)
    }

    func requestManagedAccounts() async throws {
        let request = IBManagedAccountsRequest()
        try await send(request: request)
    }

    func subscribeAccountUpdates(accountName: String, subscribe: Bool) async throws {
        let request = IBAccountUpdateRequest(accountName: accountName, subscribe: subscribe)
        try await send(request: request)
    }

    func subscribeAccountSummary(
        _ requestID: Int,
        tags: [IBAccountKey] = IBAccountKey.allValues,
        accountGroup group: String = "All"
    ) async throws {
        let request = IBAccountSummaryRequest(requestID: requestID, tags: tags, group: group)
        try await send(request: request)
    }

    func unsubscribeAccountSummary(_ requestID: Int) async throws {
        let request = IBCancelAccountSummaryRequest(requestID: requestID)
        try await send(request: request)
    }

    func subscribeAccountSummaryMulti(
        _ requestID: Int,
        accountName: String,
        ledger: Bool = true,
        modelCode: String? = nil
    ) async throws {
        let request = IBAccountSummaryMultiRequest(
            requestID: requestID,
            accountName: accountName,
            ledger: ledger,
            model: modelCode
        )
        try await send(request: request)
    }

    func unsubscribeAccountSummaryMulti(_ requestID: Int) async throws {
        let request = IBAccountSummaryMultiCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func subscribeAccountPNL(_ requestID: Int, account: String, modelCode: [String]? = nil) async throws {
        let request = IBAccountPNLRequest(requestID: requestID, accountName: account, model: modelCode)
        try await send(request: request)
    }

    func unsubscribeAccountPNL(_ requestID: Int) async throws {
        let request = IBAccountPNLCancellation(requestID: requestID)
        try await send(request: request)
    }

    func requestMarketRule(_ requestID: Int) async throws {
        let request = IBMarketRuleRequest(requestID: requestID)
        try await send(request: request)
    }

    func firstDatapointDate(
        _ requestID: Int,
        contract: IBContract,
        barSource: IBBarSource = .trades,
        extendedTrading: Bool = false
    ) async throws {
        let request = IBHeadTimestampRequest(
            requestID: requestID,
            contract: contract,
            source: barSource,
            extendedTrading: extendedTrading
        )
        try await send(request: request)
    }

    func requestPriceHistory(
        _ requestID: Int,
        contract: IBContract,
        barSize size: IBBarSize,
        barSource: IBBarSource,
        lookback: DateInterval,
        extendedTrading: Bool = false,
        includeExpired: Bool = false
    ) async throws {
        let request = IBPriceHistoryRequest(
            requestID: requestID,
            contract: contract,
            size: size,
            source: barSource,
            lookback: lookback,
            extendedTrading: extendedTrading,
            includeExpired: includeExpired
        )

        try await send(request: request)
    }

    func subscribeRealTimeBar(
        _ requestID: Int,
        contract: IBContract,
        barSize _: IBBarSize,
        barSource: IBBarSource,
        extendedTrading: Bool = false
    ) async throws {
        let request = IBRealTimeBarRequest(
            requestID: requestID,
            contract: contract,
            source: barSource,
            extendedTrading: extendedTrading
        )
        try await send(request: request)
    }

    func unsubscribeRealTimeBar(_ requestID: Int) async throws {
        let request = IBRealTimeBarCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func requestMarketData(
        _ requestID: Int,
        contract: IBContract,
        events: [IBMarketDataRequest.SubscriptionType] = [],
        snapshot: Bool = false,
        regulatory: Bool = false
    ) async throws {
        let request = IBMarketDataRequest(
            requestID: requestID,
            contract: contract,
            events: events,
            snapshot: snapshot,
            regulatory: regulatory
        )
        try await send(request: request)
    }

    func subscribeMarketData(
        _ requestID: Int,
        contract: IBContract,
        snapshot: Bool = false,
        regulatory: Bool = false
    ) async throws {
        try await requestMarketData(requestID, contract: contract, events: [], snapshot: snapshot, regulatory: regulatory)
    }

    func unsubscribeMarketData(_ requestID: Int) async throws {
        let request = IBMarketDataCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func cancelHistoricalData(_ requestID: Int) async throws {
        let request = IBIBPriceHistoryCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func subscribeMarketDepth(_ requestID: Int, contract: IBContract, rows: Int, smart: Bool = false) async throws {
        let request = IBMarketDepthRequest(requestID: requestID, contract: contract, rows: rows, smart: smart)
        try await send(request: request)
    }

    func unsubscribeMarketDepth(_ requestID: Int) async throws {
        let request = IBMarketDepthCancellation(requestID: requestID)
        try await send(request: request)
    }

    func requestTickByTick(
        _ requestID: Int,
        contract: IBContract,
        tickType: IBTickRequest.TickType,
        tickCount: Int,
        ignoreSize: Bool = true
    ) async throws {
        let request = IBTickRequest(
            requestID: requestID,
            contract: contract,
            type: tickType,
            count: tickCount,
            ignoreSize: ignoreSize
        )
        try await send(request: request)
    }

    func cancelTickByTickData(_ requestID: Int) async throws {
        let request = IBTickCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func historicalTicks(
        _ requestID: Int,
        contract: IBContract,
        numberOfTicks: Int,
        interval: DateInterval,
        whatToShow: IBTickHistoryRequest.TickSource,
        useRth: Bool,
        ignoreSize: Bool
    ) async throws {
        let request = IBTickHistoryRequest(
            requestID: requestID,
            contract: contract,
            count: numberOfTicks,
            interval: interval,
            source: whatToShow,
            extendedHours: useRth,
            ignoreSize: ignoreSize
        )
        try await send(request: request)
    }

    func subscribePositions() async throws {
        let request = IBPositionRequest()
        try await send(request: request)
    }

    func unsubscribePositions() async throws {
        let request = IBPositionCancellationRequest()
        try await send(request: request)
    }

    func subscribePositionsMulti(_ requestID: Int, accountName: String, modelCode: String = "") async throws {
        let request = IBMultiPositionRequest(requestID: requestID, accountName: accountName, model: modelCode)
        try await send(request: request)
    }

    func unsubscribePositionsMulti(_ requestID: Int) throws {
        let _ = IBMultiPositionCancellationRequest(requestID: requestID)
    }

    func subscribePositionPNL(_ requestID: Int, accountName: String, contractID: Int, modelCode: [String]? = nil)
    async throws
    {
        let request = IBPositionPNLRequest(
            requestID: requestID,
            accountName: accountName,
            contractID: contractID,
            modelCode: modelCode
        )
        try await send(request: request)
    }

    func cancelAllOrders() async throws {
        let request = IBGlobalCancelRequest()
        try await send(request: request)
    }

    func cancelOrder(_ requestID: Int) async throws {
        let request = IBCancelOrderRequest(requestID: requestID)
        try await send(request: request)
    }

    func requestExecutions(
        _ requestID: Int,
        clientID: Int? = nil,
        accountName: String? = nil,
        date: Date? = nil,
        symbol: String? = nil,
        securityType type: IBSecuritiesType? = nil,
        market: IBExchange? = nil,
        side: IBAction? = nil
    ) async throws {
        let request = IBExcecutionRequest(
            requestID: requestID,
            clientID: clientID,
            accountName: accountName,
            date: date,
            symbol: symbol,
            securityType: type,
            market: market,
            side: side
        )
        try await send(request: request)
    }

    func requestOpenOrders() async throws {
        let request = IBOpenOrderRequest()
        try await send(request: request)
    }

    func requestAllOpenOrders() async throws {
        let request = IBOpenOrderRequest.all()
        try await send(request: request)
    }

    func requestAllOpenOrders(autoBind: Bool) async throws {
        let request = IBOpenOrderRequest.autoBind(autoBind)
        try await send(request: request)
    }

    func requestCompletedOrders(apiOnly: Bool) async throws {
        let request = IBCompletedOrdersRequest(apiOnly: apiOnly)
        try await send(request: request)
    }

    func placeOrder(_ orderId: Int, order: IBOrder) async throws {
        let request = IBPlaceOrderRequest(requestID: orderId, order: order)
        try await send(request: request)
    }

    func subscribeNews(_ requestID: Int, contract: IBContract, snapshot: Bool = false, regulatory: Bool = false)
    async throws
    {
        try await requestMarketData(requestID, contract: contract, events: [], snapshot: snapshot, regulatory: regulatory)
    }

    func searchSymbols(_ requestID: Int, nameOrSymbol text: String) async throws {
        let request = IBSymbolSearchRequest(requestID: requestID, text: text)
        try await send(request: request)
    }

    func contractDetails(_ requestID: Int, contract: IBContract) async throws {
        let request = IBContractDetailsRequest(requestID: requestID, contract: contract)
        try await send(request: request)
    }

    func subscribeFundamentals(
        _ requestID: Int,
        contract: IBContract,
        reportType: IBFundamantalsRequest.ReportType
    ) async throws {
        let request = IBFundamantalsRequest(requestID: requestID, contract: contract, reportType: reportType)
        try await send(request: request)
    }

    func unsubscribeFundamentals(_ requestID: Int) async throws {
        let request = IBFundamantalsCancellationRequest(requestID: requestID)
        try await send(request: request)
    }

    func optionChain(_ requestID: Int, underlying contract: IBContract, exchange: IBExchange? = nil) async throws {
        let request = IBOptionChainRequest(requestID: requestID, underlying: contract, exchange: exchange)
        try await send(request: request)
    }
}
