//: [Previous](@previous)

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Foundation
import IBKit

extension IBPriceBar {
    func convertToProperBar(with duration: TimeInterval) -> PriceBar {
        PriceBar(
            date: self.date,
            duration: duration,
            open: self.open,
            high: self.high,
            low: self.low,
            close: self.close,
            volume: self.volume,
            wap: self.wap,
            count: self.count
        )
    }
}

struct PriceBar {
    var date: Date
    var duration: TimeInterval
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double?
    var wap: Double?
    var count: Int?
    
    init(date: Date, duration: TimeInterval, open: Double, high: Double, low: Double, close: Double, volume: Double? = nil, wap: Double? = nil, count: Int? = nil) {
        self.date = date
        self.duration = duration
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.wap = wap
        self.count = count
    }
}

protocol AnyPriceUpdate{
    associatedtype PriceValue
    var contract: IBContract { get }
    var resolution: TimeInterval { get }
    var prices: PriceValue { get }
}

struct PriceHistory: AnyPriceUpdate{
    typealias PriceValue = [PriceBar]
    var contract: IBContract
    var resolution: TimeInterval
    var prices: PriceValue
    
    init(contract: IBContract, resolution: TimeInterval, prices: PriceValue) {
        self.contract = contract
        self.resolution = resolution
        self.prices = prices
    }
}

struct PriceUpdate: AnyPriceUpdate{
    typealias PriceValue = PriceBar
    var contract: IBContract
    var resolution: TimeInterval
    var prices: PriceValue
    
    init(contract: IBContract, resolution: TimeInterval, prices: PriceValue) {
        self.contract = contract
        self.resolution = resolution
        self.prices = prices
    }
}

public class IBAccount: Equatable, Identifiable, Hashable{
    
    public let id: String
    
    // parameters here
    
    public init(id: String) {
        self.id = id
    }
    
    public func update(_ event: IBAccountUpdate){
        print(event)
    }
    
    public static func == (lhd: IBAccount, rhd: IBAccount) -> Bool {
        return lhd.id == rhd.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

public enum BrokerError: LocalizedError{
    case requestError(_ details: String)
    case somethingWentWrong(_ details: String)
}

public protocol AnyQuote{
    var contract: IBContract {get}
}


struct QuoteEvent: AnyQuote{
    
    var contract: IBContract
    var date: Date
    var type: IBTickType
    var value: Double
    
    public init(date: Date, contract: IBContract, type: IBTickType, value: Double) {
        self.date = date
        self.contract = contract
        self.type = type
        self.value = value
    }
    
}

struct QuoteTimestap: AnyQuote{
    var contract: IBContract
    var date: Date
}

struct QuoteExchange: AnyQuote{
    var contract: IBContract
    var exchange: String
}

struct QuoteDataType: AnyQuote{
    var contract: IBContract
    var type: IBMarketDataType
    
    public init(contract: IBContract,type: IBMarketDataType) {
        self.contract = contract
        self.type = type
    }
}

public protocol IBAnyOrderEvent{}
extension IBOpenOrder: IBAnyOrderEvent{}
extension IBOrderStatus: IBAnyOrderEvent{}
extension IBOrderExecution: IBAnyOrderEvent{}

@available(macOS 14.0, *)
public actor SimulatedBroker {
    public let api: IBClient

    public init(id: Int) {
        self.api = IBClient.paper(id: id)
        self.api.debugMode = false
    }

    public func connect() async throws {
        try await api.connect()
    }

    public func disconnect() async {
        await api.disconnect()
    }

    // MARK: - Live Price Bar Stream

    func priceBarStream(for contract: IBContract, extendedSession: Bool = false) async throws -> AsyncStream<any AnyPriceUpdate> {
        let requestID = api.nextRequestID
        let source: IBBarSource = [.cfd, .forex, .crypto].contains(contract.securitiesType) ? .midpoint : .trades
        let request = IBRealTimeBarRequest(requestID: requestID, contract: contract, source: source, extendedTrading: extendedSession)
        try api.send(request: request)

        return AsyncStream { continuation in
            Task {
                for await event in await api.eventFeed {
                    guard let indexed = event as? IBIndexedEvent, indexed.requestID == requestID else { continue }

                    switch event {
                    case let event as IBPriceBarUpdate:
                        let bar = event.bar.convertToProperBar(with: 5)
                        continuation.yield(PriceUpdate(contract: contract, resolution: 5, prices: bar))

                    case let error as IBServerError:
                        print("❌ IB Error: \(error.message)")
                        continuation.finish()
                        return

                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Historical Price Data

    func historicalPrice(for contract: IBContract, interval: DateInterval, size: IBBarSize, extendedSession: Bool = false) async throws -> PriceHistory {
        let requestID = api.nextRequestID
        let source: IBBarSource = [.cfd, .forex, .crypto].contains(contract.securitiesType) ? .midpoint : .trades
        let request = IBPriceHistoryRequest(requestID: requestID, contract: contract, size: size, source: source, lookback: interval, extendedTrading: extendedSession)
        
        // Delay request, so we can register 1st `api.eventFeed` subscriber

        for await event in try await api.stream(request: request) {
            print("event \(String(describing: event))")
            switch event {
            case let event as IBPriceHistory:
                let resolution = size.timeInterval
                let series = event.prices.map { $0.convertToProperBar(with: resolution) }
                return PriceHistory(contract: contract, resolution: resolution, prices: series)

            case let error as IBServerError:
                throw BrokerError.requestError(error.message)

            default:
                print("Unexpected event: \(String(describing: event))")
                continue
            }
        }

        throw BrokerError.somethingWentWrong("No response received")
    }

    // MARK: - Contract Validation

    public func validateContract(_ contract: IBContract) async throws -> IBContractDetails {
        let requestID = api.nextRequestID
        let request = IBContractDetailsRequest(requestID: requestID, contract: contract)

        for await event in try await api.stream(request: request) {
            switch event {
            case let event as IBContractDetails:
                return event

            case let error as IBServerError:
                throw BrokerError.requestError(error.message)

            default:
                continue
            }
        }

        throw BrokerError.somethingWentWrong("No contract details received")
    }

    // MARK: - Quote Stream

    public func quoteStream(for contract: IBContract) async throws -> AsyncStream<AnyQuote> {
        let requestID = api.nextRequestID
        let request = IBMarketDataRequest(requestID: requestID, contract: contract)

        return AsyncStream { continuation in
            Task {
                for await event in try await api.stream(request: request) {
                    switch event {
                    case let tick as IBTick:
                        continuation.yield(QuoteEvent(date: tick.date, contract: contract, type: tick.type, value: tick.value))

                    case let ts as IBTickTimestamp:
                        continuation.yield(QuoteTimestap(contract: contract, date: Date(timeIntervalSince1970: ts.value)))

                    case let ex as IBTickExchange:
                        continuation.yield(QuoteExchange(contract: contract, exchange: ex.value))

                    case let type as IBCurrentMarketDataType:
                        continuation.yield(QuoteDataType(contract: contract, type: type.type))

                    case let error as IBServerError:
                        print("❌ IB Error: \(error.message)")
                        continuation.finish()
                        return

                    default:
                        continue
                    }
                }
            }
        }
    }
}

// Usage example in playground or app:
Task {
    let broker = SimulatedBroker(id: 999)
    let aapl = IBContract.equity("AAPL", currency: "USD")
    let interval = DateInterval.lookback(1, unit: .minute, until: Date().addingTimeInterval(-300))
    
    try await broker.connect()
    let result = try await broker.historicalPrice(for: aapl, interval: interval, size: IBBarSize.minute)
    print(result)
    
    for await update in try await broker.priceBarStream(for: aapl) {
        print(update)
    }

    await MainActor.run {
        PlaygroundPage.current.finishExecution()
    }
}

//: [Next](@next)
