# IBKit - Interactive Brokers API swiftified

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/stensoosaar/IBKit#license) ![Swift](https://img.shields.io/badge/swift-5.5-blue.svg) ![Xcode 13.0+](https://img.shields.io/badge/Xcode-13.0%2B-blue.svg) ![macOS 12+](https://img.shields.io/badge/macOS-12.0%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-blue.svg)](https://github.com/apple/swift-package-manager)

IBKit is open source Interactive Brokers API library written in Swift. It allows you to automate trades, retrieve market data and monitor positions and orders. Offering both live and paper trading capabilities, it can be used as an algo trading platform or as an backtesting datasource. In latter case you need to write your own portfolio accounting and performance measurement methods.

The software is not an official API and is not affiliated or related with Interactive Brokers.

## Conformance
The current version should conform with IB API version 10.24. It is the aim to update the software with to MacOS major releases and include also better bites from TWS API.

## Current status
- Common features seems to work fine but complex orders may generate errors. 
- Some tick events (like dividends) needs better implementation as separate event.
- FA Accounts are not currently sypported

## Requirements
- [IB Gateway](https://www.interactivebrokers.com/en/trading/ibgateway-stable.php).
- macOS 12+
- Swift 5.5+
- XCode 13+

## Setting up IB Gateway
- Launch IB Gateway, select IB Api as interface and use your live or paper trading credentials to log in.
- To prevent IB Gateway/TWS to close application on your specified time, you need to select “Restart” option instead of “Auto logoff” under Configuration>Lock and Exit menu.
**IB maintains its servers on Saturday early mornings (GMT) and the service is disrupted for a few hours. They also restart their servers on each morning so your gateway or workstation will be disconnected for a minute or two.**
- Pay attention to your Master Client ID, host and port as you will need them when initiating new client. You find these values 
under Configuration>Settings>API>Settings menu.
- Select UTC format for sending instrument-specific attributes 
- If you want to submit orders, you shall also uncheck Read Only API from Configuration>Settings>API>Settings menu.

## Getting Started
Create a new Xcode project and navigate to `File > Swift Packages > Add Package Dependency`. Enter the url `https://github.com/stensoosaar/IBKit` and tap `Next`. Choose the `main` branch, and on the next screen, check off the packages as needed.

## How to use?
While the api calls closely resemble IB's own API, the responses are provided by using dedicated data publishers for market, account and system events. 

```
	var subscriptions: [AnyCancellable] = []

	client.marketEventFeed
		.sink { event in 
			handle event
		}
		.store(in: &subscriptions)

	do {
		let requestID = client.getNextID()
		let interval = DateInterval.lookback(10, unit: .minute, until: .distantFuture)
		try client.requestPriceHistory(requestID, contract: contract, barSize: IBBarSize.day, barSource: IBBarSource.bidAsk, lookback: interval)
	} catch {
		print(error.localizedDescription)
	}
```
For more complex tasks it might be convient to create your own custom publishers pairing request and response data or handle object mapping. 

 ```
class SimulatedBroker{

	var api: IBClient

	func priceHistoryPublisher(_ interval: DateInterval, size: IBBarSize, contract: IBContract, extendedSession: Bool = false) throws -> AnyPublisher<AnyPriceUpdate, CustomAPIError>{
			
		let requestID = api.nextRequestID
		let source: IBBarSource = [.cfd, .forex, .crypto].contains{$0 == contract.securitiesType} ? .midpoint : .trades
		let request = IBPriceHistoryRequest(requestID: requestID, contract: contract, size: size, source: source, lookback: interval, extendedTrading: extendedSession)
		try api.send(request: request)
		
		return AnyPublisher(self.api.eventFeed
			.setFailureType(to: CustomAPIError.self)
			.compactMap { $0 as? IBIndexedEvent }
			.filter { $0.requestID == requestID }
			.tryMap{ response -> (any AnyPriceUpdate) in
				switch response {
				   // handle response / error here 
				}
			.mapError { $0 as! CustomAPIError }
			.eraseToAnyPublisher()
		)
			
	}
}


let broker = SimulatedBroker(id: 0)
var subscriptions: [AnyCancellable] = []
broker.api.connect()

do{
	let contract = IBContract.future(localSymbol: "MESM4", currency: "USD")
	let interval = DateInterval.lookback(10, unit: .minute, until: .distantFuture)
	try broker.priceHistoryPublisher(interval, size: .minute, contract: contract)
		.sink { completion in
			print(completion)
		} receiveValue: { response in
			print(respinse)
		}
		.store(in: &subscriptions)
} catch{
	print(error.localizedDescription)
}

```

**Most of IB market data messages are stripped down from context (e.g. contract symbol, bar size, bar source) and if you are using multiple contracts and / or multiple timeframes you should store your request first and map the incoming messages to stored request parameters by using requestID.**

See also included playgrounds
