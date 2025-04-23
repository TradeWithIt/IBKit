//
//  IBOrder.swift
//	IBKit
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

public struct IBOrder: Sendable {
    public enum Status: String, Sendable, Codable {
        case apiPending = "ApiPending"
        case apiCancelled = "ApiCancelled"
        case preSubmitted = "PreSubmitted"
        case pendingCancel = "PendingCancel"
        case cancelled = "Cancelled"
        case submitted = "Submitted"
        case filled = "Filled"
        case inactive = "Inactive"
        case pendingSubmit = "PendingSubmit"
        case unknown = "Unknown"
    }

    public struct OrderState: Sendable, IBCodable {
        public var status: IBOrder.Status
        public var initMarginBefore: Double?
        public var maintMarginBefore: Double?
        public var equityWithLoanBefore: Double?
        public var initMarginChange: Double?
        public var maintMarginChange: Double?
        public var equityWithLoanChange: Double?

        public var initMarginAfter: Double?
        public var maintMarginAfter: Double?
        public var equityWithLoanAfter: Double?
        public var commission: Double?
        public var minCommission: Double?
        public var maxCommission: Double?
        public var commissionCurrency: Double?
        public var warning: String?

        public var completedTime: Date?
        public var completedStatus: String?

        public init(with status: IBOrder.Status) {
            self.status = status
        }

        public init(from decoder: IBDecoder) throws {
            guard let serverVersion = decoder.serverVersion else {
                throw IBClientError.decodingError("No server version found. Check the connection!")
            }

            var container = try decoder.unkeyedContainer()
            status = try container.decode(IBOrder.Status.self)

            if serverVersion >= IBServerVersion.WHAT_IF_EXT_FIELDS {
                initMarginBefore = try container.decodeOptional(Double.self)
                maintMarginBefore = try container.decodeOptional(Double.self)
                equityWithLoanBefore = try container.decodeOptional(Double.self)
                initMarginChange = try container.decodeOptional(Double.self)
                maintMarginChange = try container.decodeOptional(Double.self)
                equityWithLoanChange = try container.decodeOptional(Double.self)
            }

            initMarginAfter = try container.decodeOptional(Double.self)
            maintMarginAfter = try container.decodeOptional(Double.self)
            equityWithLoanAfter = try container.decodeOptional(Double.self)
            commission = try container.decodeOptional(Double.self)
            minCommission = try container.decodeOptional(Double.self)
            maxCommission = try container.decodeOptional(Double.self)
            commissionCurrency = try container.decodeOptional(Double.self)
            warning = try container.decodeOptional(String.self)
        }

        public func encode(to encoder: IBEncoder) throws {
            let _ = encoder.unkeyedContainer()
        }
    }

    public var orderState: OrderState = .init(with: .unknown)

    /// underlying contract
    public var contract: IBContract

    /// The API client's order id.
    public var orderID: Int = 0

    /// The API client id which placed the order.
    public var clientID: Int = 0

    /// The Host order identifier.
    public var permID: Int = 0

    public var action: IBAction

    /// The number of positions being bought/sold.
    public var totalQuantity: Double = 0

    public enum OrderType: String, Sendable, Codable {
        case MARKET = "MKT"
        case LIMIT = "LMT"
        case STOP = "STP"
        case STOP_LIMIT = "STP LMT"
        case RELATIVE = "REL"
        case TRAILING = "TRAIL"
        case BOX_TOP = "BOX TOP"
        case FIX_PEGGED = "FIX PEGGED"
        case LIMIT_IF_TOUCH = "LIT"
        case LMT_PLUS_MKT = "LMT + MKT"
        case LIMIT_ON_CLOSE = "LOC"
        case MARKET_IF_TOUCHED = "MIT"
        case MKT_PRT = "MKT PRT"
        case MARKET_ON_CLOSE = "MOC"
        case MARKET_TO_LIMIT = "MTL"
        case PASSV_REL = "PASSV REL"
        case PEG_BENCH = "PEG BENCH"
        case PEG_MID = "PEG MID"
        case PEG_MKT = "PEG MKT"
        case PEG_PRIM = "PEG PRIM"
        case PEG_BEST = "PEG BEST"
        case PEG_STK = "PEG STK"
        case REL_PLUS_LMT = "REL + LMT"
        case REL_PLUS_MKT = "REL + MKT"
        case SNAP_MID = "SNAP MID"
        case SNAP_MKT = "SNAP MKT"
        case SNAP_PRIM = "SNAP PRIM"
        case STP_PRT = "STP PRT"
        case TRAIL_LIMIT = "TRAIL LIMIT"
        case TRAIL_LIT = "TRAIL LIT"
        case TRAIL_LMT_PLUS_MKT = "TRAIL LMT + MKT"
        case TRAIL_MIT = "TRAIL MIT"
        case TRAIL_REL_PLUS_MKT = "TRAIL REL + MKT"
        case VOL
        case VWAP
        case QUOTE
        case PEG_PRIM_VOL = "PPV"
        case PEG_MID_VOL = "PDV"
        case PEG_MKT_VOL = "PMV"
        case PEG_SRF_VOL = "PSV"
    }

    /// The order's type.
    public var orderType: OrderType

    /// Used for limit, stop-limit and relative orders. In all other cases specify zero. For relative orders with no limit price, also specify zero.
    public var lmtPrice: Double?

    /// Generic field to contain the stop price for STP LMT orders, trailing amount, etc.
    public var auxPrice: Double?

    public enum TimeInForce: String, Sendable, Codable {
        /// Valid for the day only.
        case day = "DAY"

        /// Good until canceled. The order will continue to work within the system and in the marketplace until it executes or is canceled.
        /// GTC orders will be automatically be cancelled under the following conditions: If a corporate action on a security results in a stock
        /// split (forward or reverse), exchange for shares, or distribution of shares. If you do not log into your IB account for 90 days.
        case untilCancelled = "GTC"

        /// Immediate or Cancel. Any portion that is not filled as soon as it becomes available in the market is canceled.
        case immidiateOrCancel = "IOC"

        /// Good until Date. It will remain working within the system and in the marketplace until it executes or until the close of the market on the date specified
        case goodTilDate = "GTD"

        /// Fill-or-Kill order does not execute as soon as it becomes available, the entire order is canceled.
        case fillOrKill = "FOK"

        ///  Day until Canceled
        case dayTilCanceled = "DTC"
    }

    /// Generic field to contain the stop price for STP LMT orders, trailing amount, etc.
    public var tif: TimeInForce = .untilCancelled

    ///
    public var activeStartTime: Date? // for GTC orders

    ///
    public var activeStopTime: Date? // for GTC orders

    /// One-Cancels-All group identifier.
    public var ocaGroup: String? // one cancels all group name

    public enum OCAType: Int, Sendable, Codable {
        /// Cancel all remaining orders with block.
        case cancelBlock = 1

        /// Remaining orders are proportionately reduced in size with block.
        case reduceWithBlock = 2

        /// Remaining orders are proportionately reduced in size with no block.
        case reduceNoBlock = 3
    }

    /// Tells how to handle remaining orders in an OCA group when one order or part of an order executes. If you use a value "with block" it gives
    /// the order overfill protection. This means that only one order in the group will be routed at a time to remove the possibility of an overfill.
    public var ocaType: OCAType?

    /// The order reference. Intended for institutional customers only, although all customers may use it to identify the API client that sent the
    /// order when multiple API clients are running.
    public var orderRef: String?

    /// Specifies whether the order will be transmitted by TWS. If set to false, the order will be created at TWS but will not be sent.
    public var transmit: Bool = true

    /// The order ID of the parent order, used for bracket and auto trailing stop orders.
    public var parentId: Int = 0

    /// If set to true, specifies that the order is an ISE Block order.
    public var blockOrder: Bool = false

    /// If set to true, specifies that the order is a Sweep-to-Fill order.
    public var sweepToFill: Bool = false

    /// The publicly disclosed order size, used when placing Iceberg orders.
    public var displaySize: Int?

    public enum TriggerMethod: Int, Sendable, Codable {
        /// stop orders are triggered based on two consecutive bid or ask prices.
        case doubleBidAsk = 1

        /// stop orders are triggered based on the last price.
        case last = 2

        /// 3 double last function.
        case doubleLast = 3

        /// 4 bid/ask function.
        case bidAsk = 4

        /// 7 last or bid/ask function.
        case lastOrBidAsk = 7

        /// 8 mid-point function
        case midPoint = 8
    }

    /// Specifies how Simulated Stop, Stop-Limit and Trailing Stop orders are triggered. Valid values are:
    public var triggerMethod: TriggerMethod?

    /// If set to true, allows orders to also trigger or fill outside of regular trading hours.
    public var outsideRth: Bool = false

    /// If set to true, the order will not be visible when viewing the market depth. This option only applies to orders routed to the ISLAND exchange.
    public var hidden: Bool = false

    /// Specifies the date and time after which the order will be active. Format: yyyymmdd hh:mm:ss {optional Timezone}.
    public var goodAfterTime: Date?

    /// The date and time until the order will be active. You must enter GTD as the time in force to use this string.
    /// The trade's "Good Till Date," format "YYYYMMDD hh:mm:ss (optional time zone)".
    public var goodTillDate: Date?

    public enum Rule80A: String, Sendable, Codable {
        case individual = "I"
        case agency = "A"
        case agentOtherMember = "W"
        case individualPTIA = "J"
        case agencyPTIA = "U"
        case agentOtherMemberPTIA = "M"
        case individualPT = "K"
        case agencyPT = "Y"
        case agentOtherMemberPT = "N"
        case unknown = ""
    }

    ///
    public var rule80A: Rule80A?

    /// Indicates whether or not all the order has to be filled on a single execution.
    public var allOrNone: Bool = false

    /// Identifies a minimum quantity order type.
    public var minQty: Int?

    /// The percent offset amount for relative orders.
    public var percentOffset: Double?

    /// Overrides TWS constraints. Precautionary constraints are defined on the TWS Presets page, and help ensure tha tyour price and
    /// size order values are reasonable. Orders sent from the API are also validated against these safety constraints, and may be rejected
    /// if any constraint is violated. To override validation, set this parameter’s value to True.
    public var overridePercentageConstraints: Bool = false

    /// Trail stop price for TRAILIMIT orders.
    public var trailStopPrice: Double?

    /// Specifies the trailing amount of a trailing stop order as a percentage. Observe the following guidelines when using the trailingPercent field:
    public var trailingPercent: Double?

    // MARK: - financial advisors only

    /// The Financial Advisor group the trade will be allocated to. Use an empty string if not applicable.
    public var faGroup: String?

    /// The Financial Advisor allocation profile the trade will be allocated to. Use an empty string if not applicable.
    public var faProfile: String?

    /// The Financial Advisor allocation method the trade will be allocated to. Use an empty string if not applicable.
    public var faMethod: String?

    /// The Financial Advisor percentage concerning the trade's allocation. Use an empty string if not applicable.
    public var faPercentage: String?

    // MARK: - institutional (ie non-cleared) accounts only

    /// Used only when shortSaleSlot is 2. For institutions only. Indicates the location where the shares to short come from.
    /// Used only when short sale slot is set to 2 (which means that the shares to short are held elsewhere and not with IB).
    public var designatedLocation: String?

    public enum OpenClose: String, Sendable, Codable {
        case open = "O"
        case close = "C"
    }

    /// For institutional customers only. Valid values are O (open), C (close). Available for institutional clients to determine
    /// if this order is to open or close a position. When Action = "BUY" and OpenClose = "O" this will open a new position.
    /// When Action = "BUY" and OpenClose = "C" this will close an existing short position.
    public var openClose: OpenClose?

    public enum Origin: Int, Sendable, Codable {
        case customer = 0
        case firm = 1
        case unknown = 2
    }

    /// The order's origin. Same as TWS "Origin" column. Identifies the type of customer from which the order originated. Valid values are 0 (customer), 1 (firm).
    public var origin: Origin = .customer

    /// For institutions only. Valid values are: 1 (broker holds shares) or 2 (shares come from elsewhere).
    public enum Custody: Int, Sendable, Codable {
        case broker = 1
        case external = 2
    }

    public var shortSaleSlot: Custody?

    /// Only available with IB Execution-Only accounts with applicable securities Mark order as exempt from short sale uptick rule.
    public var exemptCode: Int = -1

    // MARK: - SMART routing only

    /// The amount off the limit price allowed for discretionary orders.
    public var discretionaryAmt: Double = 0

    @available(*, deprecated)
    public var eTradeOnly: Bool = true

    @available(*, deprecated)
    public var firmQuoteOnly: Bool = true

    @available(*, deprecated)
    public var nbboPriceCap: Double?

    /// Use to opt out of default SmartRouting for orders routed directly to ASX.
    ///  This attribute defaults to false unless explicitly set to true.
    ///  When set to false, orders routed directly to ASX will NOT use SmartRouting.
    ///  When set to true, orders routed directly to ASX orders WILL use SmartRouting.
    public var optOutSmartRouting: Bool?

    // MARK: - BOX exchange orders only

    public enum AuctionStrategy: Int, Sendable, Codable {
        case unset = 0
        case match = 1
        case improvement = 2
        case transparent = 3
    }

    /// For BOX orders only.
    public var auctionStrategy: AuctionStrategy?

    /// The auction's starting price. For BOX orders only.
    public var startingPrice: Double?

    /// The stock's reference price.
    /// The reference price is used for VOL orders to compute the limit price sent to an exchange (whether or not Continuous Update is selected), and for price range monitoring.
    public var stockRefPrice: Double?

    /// The stock's Delta. For orders on BOX only.
    public var delta: Double?

    // MARK: - pegged to stock and VOL orders only

    /// The lower value for the acceptable underlying stock price range. For price improvement option orders on BOX and VOL orders with dynamic management.
    public var stockRangeLower: Double?

    /// The upper value for the acceptable underlying stock price range. For price improvement option orders on BOX and VOL orders with dynamic management.
    public var stockRangeUpper: Double?

    ///
    public var randomizePrice: Bool = false

    public var randomizeSize: Bool = false

    // MARK: - VOLATILITY ORDERS ONLY

    public enum VolaitilityType: Int, Sendable, Codable {
        case daily = 1
        case annual = 2
    }

    /// The option price in volatility, as calculated by TWS' Option Analytics. This value is expressed as a percent
    /// and is used to calculate the limit price sent to the exchange.
    public var volatility: Double?

    /// Values include: 1 - Daily Volatility 2 - Annual Volatility.
    public var volatilityType: VolaitilityType?

    /// Enter an order type to instruct TWS to submit a delta neutral trade on full or partial execution
    /// of the VOL order. VOL orders only. For no hedge delta order to be sent, specify NONE.
    public var deltaNeutralOrderType: String?

    /// Use this field to enter a value if the value in the deltaNeutralOrderType
    /// field is an order type that requires an Aux price, such as a REL order. VOL orders only.
    public var deltaNeutralAuxPrice: Double?

    public var deltaNeutralConId: Int?

    public var deltaNeutralSettlingFirm: String?

    public var deltaNeutralClearingAccount: String?

    public var deltaNeutralClearingIntent: String?

    /// Specifies whether the order is an Open or a Close order and is used when the hedge involves a CFD and and the order is clearing away.
    public var deltaNeutralOpenClose: String?

    /// Used when the hedge involves a stock and indicates whether or not it is sold short.
    public var deltaNeutralShortSale: Bool = false

    /// Has a value of 1 (the clearing broker holds shares) or 2 (delivered from a third party).
    /// If you use 2, then you must specify a deltaNeutralDesignatedLocation.
    public var deltaNeutralShortSaleSlot: Int?

    public var deltaNeutralDesignatedLocation: String?

    public var continuousUpdate: Bool = false

    public enum ReferencePriceType: Int, Sendable, Codable {
        case average = 1
        case bidOrAsk = 2
    }

    public var referencePriceType: ReferencePriceType?

    // MARK: - COMBO ORDERS ONLY

    /// EFP oredrs only
    public var basisPoints: Double?

    /// EFP orders only
    public var basisPointsType: Int?

    // MARK: - SCALE ORDERS ONLY

    /// Defines the size of the first, or initial, order component. For Scale orders only.
    public var scaleInitLevelSize: Int?

    /// Defines the order size of the subsequent scale order components. For Scale orders only. Used in conjunction with scaleInitLevelSize().
    public var scaleSubsLevelSize: Int?

    /// Defines the price increment between scale components. For Scale orders only. This value is compulsory.
    public var scalePriceIncrement: Double?

    public var scalePriceAdjustValue: Double?

    public var scalePriceAdjustInterval: Int?

    public var scaleProfitOffset: Double?

    public var scaleAutoReset: Bool = false

    public var scaleInitPosition: Int?

    public var scaleInitFillQty: Int?

    public var scaleRandomPercent: Bool = false

    public var scaleTable = ""

    // MARK: - HEDGE ORDERS

    public enum HedgeType: String, Sendable, Codable {
        case delta = "D"
        case beta = "B"
        case forex = "F"
        case pair = "P"

        var hedgeParameter: String? {
            switch self {
            case .beta: return "Beta = x"
            case .pair: return "ratio = y"
            default: return nil
            }
        }
    }

    /// For hedge orders
    public var hedgeType: HedgeType?

    /// Beta = x for Beta hedge orders, ratio = y for Pair hedge order
    public var hedgeParam: String?

    // MARK: - Clearing info

    /// The account the trade will be allocated to.
    public var account: String?

    /// Institutions only. Indicates the firm which will settle the trade.
    public var settlingFirm: String?

    /// Specifies the true beneficiary of the order. For IBExecution customers.
    /// This value is required for FUT/FOP orders for reporting to the exchange.
    public var clearingAccount: String?

    /// For exeuction-only clients to know where do they want their shares to be cleared at.
    /// Valid values are: IB, Away, and PTA (post trade allocation).
    public enum ClearingIntent: String, Sendable, Codable {
        case ib = "IB"
        case away = "Away"
        case postTradeAllocation = "PTA"
    }

    public var clearingIntent: ClearingIntent?

    // MARK: - ALGO ORDERS ONLY

    public enum AlgoStrategy: String, Sendable, Codable {
        case arrivalPrive = "arrivalPx"
        case darkIce = "DarkIce"
        case volumePercentage = "PctVol"
        case timeWeightedAveragePrice = "Twap"
        case volumeWeightedAveragePrice = "Vwap"
    }

    /// The algorithm strategy. As of API verion 9.6, the following algorithms are supported
    public var algoStrategy: AlgoStrategy?

    ///
    public var algoParams: [String: String]?

    ///
    public var smartComboRoutingParams: [String: String]?

    /// ??
    public var algoId: String?

    // MARK: - What-if

    /// Allows to retrieve the commissions and margin information.
    /// When placing an order with this attribute set to true, the order will not be placed as such.
    /// Instead it will used to request the commissions and margin information that would result from this order.
    public var whatIf: Bool = false

    // MARK: _Not Held

    /// Orders routed to IBDARK are tagged as “post only” and are held in IB's order book,
    /// where incoming SmartRouted orders from other IB customers are eligible to trade against them.
    /// For IBDARK orders only.
    public var notHeld: Bool = false

    /// ??
    public var solicited: Bool = false

    // MARK: - models

    /// Model code
    public var modelCode: String?

    public struct SoftDollarTier: Sendable, IBCodable {
        var value: String
        var name: String
        var displayName: String

        init(name: String, value: String, displayName: String) {
            self.value = value
            self.name = name
            self.displayName = displayName
        }

        public init(from decoder: IBDecoder) throws {
            var container = try decoder.unkeyedContainer()
            name = try container.decode(String.self)
            value = try container.decode(String.self)
            displayName = try container.decode(String.self)
        }

        public func encode(to encoder: IBEncoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(name.self)
            try container.encode(value.self)
            try container.encode(displayName.self)
        }
    }

    /// Define the Soft Dollar Tier used for the order. Only provided for registered professional advisors and hedge and mutual funds.
    public var softDollarTier: SoftDollarTier?

    // MARK: - order combo legs

    public struct ComboLeg: Sendable, IBCodable {
        /// The order's leg's price.
        public var price: Double

        public init(price: Double) {
            self.price = price
        }

        public init(from decoder: IBDecoder) throws {
            var container = try decoder.unkeyedContainer()
            price = try container.decode(Double.self)
        }

        public func encode(to encoder: IBEncoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(price)
        }
    }

    /// List of Per-leg price following the same sequence combo legs are added. The combo price must be left unspecified when using per-leg prices.
    public var orderComboLegs: [ComboLeg]?

    /// ??
    public var orderMiscOptions: [String: String]?

    // MARK: - VER PEG2BENCH fields:

    /// Pegged-to-benchmark orders: this attribute will contain the conId of the contract against which the order will be pegged.
    public var referenceContractId: Int = 0

    /// Pegged-to-benchmark orders: amount by which the order's pegged price should move.
    public var peggedChangeAmount: Double = 0.0

    /// Pegged-to-benchmark orders: indicates whether the order's pegged price should increase or decreases.
    public var isPeggedChangeAmountDecrease: Bool = false

    /// Pegged-to-benchmark orders: the amount the reference contract needs to move to adjust the pegged order.
    public var referenceChangeAmount: Double = 0.0

    /// Pegged-to-benchmark orders: the exchange against which we want to observe the reference contract.
    public var referenceExchangeId: String?

    /// Adjusted Stop orders: the parent order will be adjusted to the given type when the adjusted trigger price is penetrated.
    public var adjustedOrderType: String?

    /// Trigger Price
    public var triggerPrice: Double?

    /// Adjusted Stop orders: specifies the stop price of the adjusted (STP) parent.
    public var adjustedStopPrice: Double?

    /// Adjusted Stop orders: specifies the stop limit price of the adjusted (STPL LMT) parent.
    public var adjustedStopLimitPrice: Double?

    /// Adjusted Stop orders: specifies the trailing amount of the adjusted (TRAIL) parent.
    public var adjustedTrailingAmount: Double?

    /// Adjusted Stop orders: specifies where the trailing unit is an amount (set to 0) or a percentage (set to 1)
    public var adjustableTrailingUnit: Int?

    /// ???
    public var lmtPriceOffset: Double?

    /// Conditions determining when the order will be activated or canceled.
    public var conditions: IBOrderCondition?

    /// Conditions can determine if an order should become active or canceled.
    public var conditionsCancelOrder: Bool = false

    /// Indicates whether or not conditions will also be valid outside Regular Trading Hours.
    public var conditionsIgnoreRth: Bool = false

    // ext operator
    public var extOperator: String = ""

    // native cash quantity
    public var cashQuantity: Double?

    /// Identifies a person as the responsible party for investment decisions within the firm.
    /// Orders covered by MiFID 2 (Markets in Financial Instruments Directive 2) must include either Mifid2DecisionMaker or Mifid2DecisionAlgo field (but not both).
    /// Requires TWS 969+.
    public var mifid2DecisionMaker: String?

    /// Identifies the algorithm responsible for investment decisions within the firm. Orders covered under MiFID 2 must include either Mifid2DecisionMaker or Mifid2DecisionAlgo, but cannot have both. Requires TWS 969+.
    public var mifid2DecisionAlgo: String?

    /// For MiFID 2 reporting; identifies a person as the responsible party for the execution of a transaction within the firm. Requires TWS 969+.
    public var mifid2ExecutionTrader: String?

    /// For MiFID 2 reporting; identifies the algorithm responsible for the execution of a transaction within the firm. Requires TWS 969+.
    public var mifid2ExecutionAlgo: String?

    /// Don't use auto price for hedge.
    public var dontUseAutoPriceForHedge: Bool = false

    /// Set to true to create tickets from API orders when TWS is used as an OMS
    public var isOmsContainer: Bool = false

    /// Set to true to convert order of type 'Primary Peg' to 'D-Peg'.
    public var discretionaryUpToLimitPrice: Bool = false

    public var autoCancelDate: String?

    public var filledQuantity: Double?

    public var refFuturesConId: Int?

    public var autoCancelParent: Bool = false

    public var shareholder: String?

    public var imbalanceOnly: Bool = false

    public var routeMarketableToBbo: Bool = false

    public var parentPermId: Int = 0

    public var usePriceMgmtAlgo: Bool?

    public var duration: Int?

    public var postToAts: Int?

    public var advancedErrorOverride: String?

    public var manualOrderTime: String?

    public var minTradeQty: Int?

    public var minCompeteSize: Int?

    public var competeAgainstBestOffset: Double?

    public var midOffsetAtWhole: Double?

    public var midOffsetAtHalf: Double?
}

extension IBOrder: IBCodable {
    public func encode(to encoder: IBEncoder) throws {
        guard let serverVersion = encoder.serverVersion else {
            throw IBClientError.encodingError("Server value expected")
        }

        var container = encoder.unkeyedContainer()

        try container.encode(contract)

        if serverVersion >= IBServerVersion.SEC_ID_TYPE {
            try container.encodeOptional(contract.secId?.type)
            try container.encodeOptional(contract.secId?.value)
        }

        // order main fields
        try container.encode(action)

        if serverVersion >= IBServerVersion.FRACTIONAL_POSITIONS {
            try container.encode(totalQuantity)
        } else {
            try container.encode(Int(totalQuantity))
        }

        try container.encode(orderType)
        try container.encodeOptional(lmtPrice)
        try container.encodeOptional(auxPrice)

        // extended order fields
        try container.encode(tif)
        try container.encodeOptional(ocaGroup)
        try container.encode(account)
        try container.encodeOptional(openClose)
        try container.encodeOptional(origin)
        try container.encodeOptional(orderRef)
        try container.encodeOptional(transmit)
        try container.encodeOptional(parentId)
        try container.encodeOptional(blockOrder)
        try container.encodeOptional(sweepToFill)
        try container.encodeOptional(displaySize)
        try container.encodeOptional(triggerMethod)
        try container.encodeOptional(outsideRth)
        try container.encodeOptional(hidden)

        // combo order fields
        if contract.securitiesType == .combo {
            if let legs = contract.comboLegs {
                try container.encode(legs.count)
                if legs.count > 0 {
                    for leg in legs {
                        try container.encode(leg.conId)
                        try container.encode(leg.ratio)
                        try container.encode(leg.action)
                        try container.encode(leg.exchange)
                        try container.encode(leg.openClose)
                        try container.encode(leg.shortSaleSlot)
                        try container.encode(leg.designatedLocation)
                        if serverVersion > IBServerVersion.SSHORTX_OLD {
                            try container.encode(leg.exemptCode)
                        }
                    }
                }
            }
        }

        if contract.securitiesType == .combo && serverVersion >= IBServerVersion.ORDER_COMBO_LEGS_PRICE {
            if let legs = orderComboLegs {
                try container.encode(legs.count)
                if legs.count > 0 {
                    for leg in legs {
                        try container.encode(leg.price)
                    }
                }
            }
        }

        if contract.securitiesType == .combo && serverVersion > IBServerVersion.SMART_COMBO_ROUTING_PARAMS {
            if let params = smartComboRoutingParams {
                try container.encode(params.count)
                for (key, value) in params {
                    try container.encode(key)
                    try container.encode(value)
                }
            }
        }

        // Allocation
        // <account_code1>/<number_shares1>,<account_code2>/<number_shares2>
        // To allocate 20 shares of a 100 share order to account 'U101' and the
        // residual 80 to account 'U203' enter the following share allocation string:
        // U101/20,U203/80

        try container.encodeOptional("")
        try container.encodeOptional(discretionaryAmt)
        try container.encodeOptional(goodAfterTime)
        try container.encodeOptional(goodTillDate)

        // financial advisor methods
        try container.encodeOptional(faGroup)
        try container.encodeOptional(faMethod)
        try container.encodeOptional(faPercentage)
        if serverVersion < IBServerVersion.FA_PROFILE_DESUPPORT {
            try container.encodeOptional("")
        }

        if serverVersion >= IBServerVersion.MODELS_SUPPORT {
            try container.encodeOptional(modelCode)
        }

        // only populate when order.m_shortSaleSlot = 2
        try container.encodeOptional(shortSaleSlot)
        try container.encodeOptional(designatedLocation)

        if serverVersion >= IBServerVersion.SSHORTX_OLD {
            try container.encodeOptional(exemptCode)
        }

        try container.encodeOptional(ocaType)
        try container.encodeOptional(rule80A)
        try container.encodeOptional(settlingFirm)
        try container.encodeOptional(allOrNone)
        try container.encodeOptional(minQty)
        try container.encodeOptional(percentOffset)

        try container.encodeOptional(false)
        try container.encodeOptional(false)
        try container.encodeNil()

        try container.encodeOptional(auctionStrategy)
        try container.encodeOptional(startingPrice)
        try container.encodeOptional(stockRefPrice)
        try container.encodeOptional(delta)
        try container.encodeOptional(stockRangeLower)
        try container.encodeOptional(stockRangeUpper)
        try container.encodeOptional(overridePercentageConstraints)

        try container.encodeOptional(volatility)
        try container.encodeOptional(volatilityType)
        try container.encodeOptional(deltaNeutralOrderType)
        try container.encodeOptional(deltaNeutralAuxPrice)

        if serverVersion >= IBServerVersion.DELTA_NEUTRAL_CONID && deltaNeutralOrderType != nil {
            try container.encodeOptional(deltaNeutralConId)
            try container.encodeOptional(deltaNeutralSettlingFirm)
            try container.encodeOptional(deltaNeutralClearingAccount)
            try container.encodeOptional(deltaNeutralClearingIntent)
        }

        if serverVersion >= IBServerVersion.DELTA_NEUTRAL_OPEN_CLOSE && deltaNeutralOrderType != nil {
            try container.encodeOptional(deltaNeutralOpenClose)
            try container.encodeOptional(deltaNeutralShortSale)
            try container.encodeOptional(deltaNeutralShortSaleSlot)
            try container.encodeOptional(deltaNeutralDesignatedLocation)
        }
        try container.encodeOptional(continuousUpdate)
        try container.encodeOptional(referencePriceType)
        try container.encodeOptional(trailStopPrice)

        if serverVersion >= IBServerVersion.TRAILING_PERCENT {
            try container.encodeOptional(trailingPercent)
        }

        // SCALE ORDERS
        if serverVersion >= IBServerVersion.SCALE_ORDERS2 {
            try container.encodeOptional(scaleInitLevelSize)
            try container.encodeOptional(scaleSubsLevelSize)
        } else {
            try container.encodeOptional("")
            try container.encodeOptional(scaleInitLevelSize)
        }

        try container.encodeOptional(scalePriceIncrement)

        if serverVersion >= IBServerVersion.SCALE_ORDERS3 {
            if let increment = scalePriceIncrement {
                if increment > 0 {
                    try container.encodeOptional(scalePriceAdjustValue)
                    try container.encodeOptional(scalePriceAdjustInterval)
                    try container.encodeOptional(scaleProfitOffset)
                    try container.encodeOptional(scaleAutoReset)
                    try container.encodeOptional(scaleInitPosition)
                    try container.encodeOptional(scaleInitFillQty)
                    try container.encodeOptional(scaleRandomPercent)
                }
            }
        }

        if serverVersion >= IBServerVersion.SCALE_TABLE {
            try container.encodeOptional(scaleTable)
            try container.encodeOptional(activeStartTime)
            try container.encodeOptional(activeStopTime)
        }

        // HEDGE ORDERS
        if serverVersion >= IBServerVersion.HEDGE_ORDERS {
            try container.encodeOptional(hedgeType)
            if hedgeType != nil {
                try container.encodeOptional(hedgeParam)
            }
        }

        if serverVersion >= IBServerVersion.OPT_OUT_SMART_ROUTING {
            try container.encodeOptional(optOutSmartRouting)
        }

        if serverVersion >= IBServerVersion.PTA_ORDERS {
            try container.encodeOptional(clearingAccount)
            try container.encodeOptional(clearingIntent)
        }

        if serverVersion >= IBServerVersion.NOT_HELD {
            try container.encodeOptional(notHeld)
        }

        if serverVersion >= IBServerVersion.DELTA_NEUTRAL {
            if let underComp = contract.deltaNeutralContract {
                try container.encodeOptional(true)
                try container.encodeOptional(underComp.conId)
                try container.encodeOptional(underComp.delta)
                try container.encodeOptional(underComp.price)
            } else {
                try container.encodeOptional(false)
            }
        }

        if serverVersion >= IBServerVersion.ALGO_ORDERS {
            try container.encodeOptional(algoStrategy)
            if let strategy = algoParams {
                try container.encodeOptional(strategy.count)
                for (key, value) in strategy {
                    try container.encodeOptional(key)
                    try container.encodeOptional(value)
                }
            }
        }

        if serverVersion >= IBServerVersion.ALGO_ID {
            try container.encodeOptional(algoId)
        }

        if serverVersion >= IBServerVersion.WHAT_IF_EXT_FIELDS {
            try container.encodeOptional(whatIf)
        }

        if serverVersion >= IBServerVersion.LINKING {
            var str = ""
            if let options = orderMiscOptions {
                for (key, value) in options {
                    str += "\(key)=\(value)"
                }
            }
            try container.encodeOptional(str)
        }

        if serverVersion >= IBServerVersion.ORDER_SOLICITED {
            try container.encodeOptional(solicited)
        }

        if serverVersion >= IBServerVersion.RANDOMIZE_SIZE_AND_PRICE {
            try container.encodeOptional(randomizeSize)
            try container.encodeOptional(randomizePrice)
        }

        if serverVersion >= IBServerVersion.PEGGED_TO_BENCHMARK {
            if orderType == IBOrder.OrderType.PEG_BENCH {
                try container.encodeOptional(referenceContractId)
                try container.encodeOptional(isPeggedChangeAmountDecrease)
                try container.encodeOptional(peggedChangeAmount)
                try container.encodeOptional(referenceChangeAmount)
                try container.encodeOptional(referenceExchangeId)
            }

            if let conditions = conditions {
                try container.encodeOptional(conditions)
            } else {
                try container.encodeOptional(0)
            }

            try container.encodeOptional(adjustedOrderType)
            try container.encodeOptional(triggerPrice)
            try container.encodeOptional(lmtPriceOffset)
            try container.encodeOptional(adjustedStopPrice)
            try container.encodeOptional(adjustedStopLimitPrice)
            try container.encodeOptional(adjustedTrailingAmount)
            try container.encodeOptional(adjustableTrailingUnit)
        }

        if serverVersion >= IBServerVersion.EXT_OPERATOR {
            try container.encodeOptional(extOperator)
        }

        if serverVersion >= IBServerVersion.SOFT_DOLLAR_TIER {
            try container.encodeOptional(softDollarTier?.name)
            try container.encodeOptional(softDollarTier?.value)
        }

        if serverVersion >= IBServerVersion.CASH_QTY {
            try container.encodeOptional(cashQuantity)
        }

        if serverVersion >= IBServerVersion.DECISION_MAKER {
            try container.encodeOptional(mifid2DecisionMaker)
            try container.encodeOptional(mifid2DecisionAlgo)
        }

        if serverVersion >= IBServerVersion.MIFID_EXECUTION {
            try container.encodeOptional(mifid2ExecutionTrader)
            try container.encodeOptional(mifid2ExecutionAlgo)
        }

        if serverVersion >= IBServerVersion.AUTO_PRICE_FOR_HEDGE {
            try container.encode(dontUseAutoPriceForHedge)
        }

        if serverVersion >= IBServerVersion.ORDER_CONTAINER {
            try container.encode(isOmsContainer)
        }

        if serverVersion >= IBServerVersion.D_PEG_ORDERS {
            try container.encodeOptional(discretionaryUpToLimitPrice)
        }

        if serverVersion >= IBServerVersion.PRICE_MGMT_ALGO {
            try container.encodeOptional(usePriceMgmtAlgo)
        }

        if serverVersion >= IBServerVersion.DURATION {
            try container.encodeOptional(duration)
        }

        if serverVersion >= IBServerVersion.POST_TO_ATS {
            try container.encodeOptional(postToAts)
        }

        if serverVersion >= IBServerVersion.AUTO_CANCEL_PARENT {
            try container.encodeOptional(autoCancelParent)
        }

        if serverVersion >= IBServerVersion.ADVANCED_ORDER_REJECT {
            try container.encodeOptional(advancedErrorOverride)
        }

        if serverVersion >= IBServerVersion.MANUAL_ORDER_TIME {
            try container.encodeOptional(manualOrderTime)
        }

        // TODO: - need fixing
        if serverVersion >= IBServerVersion.PEGBEST_PEGMID_OFFSETS {
            var sendMidOffset = false
            if contract.exchange == .IBKRATS {
                try container.encodeOptional(minTradeQty)
            }

            if orderType == .PEG_BENCH {
                try container.encodeOptional(minCompeteSize)
                try container.encodeOptional(competeAgainstBestOffset)
                if competeAgainstBestOffset == Double.infinity {
                    sendMidOffset = true
                }
            } else if orderType == .PEG_MID {
                sendMidOffset = true
            }

            if sendMidOffset {
                try container.encodeOptional(midOffsetAtWhole)
                try container.encodeOptional(midOffsetAtWhole)
            }
            try container.encodeOptional(minTradeQty)
        }
    }

    public init(from decoder: IBDecoder) throws {
        let version = 45

        guard let serverVersion = decoder.serverVersion else {
            throw IBClientError.decodingError("server version not present")
        }

        var container = try decoder.unkeyedContainer()

        // decode OrderId
        orderID = try container.decode(Int.self)

        // decode ContractFields
        contract = try container.decode(IBContract.self)

        // decode Action
        action = try container.decode(IBAction.self)
        // print("action", action, decoder.cursor)

        // decode TotalQuantity
        totalQuantity = try container.decode(Double.self)

        // decode OrderType
        orderType = try container.decode(IBOrder.OrderType.self)

        // decode LmtPrice
        lmtPrice = try container.decodeOptional(Double.self)

        // decode AuxPrice
        auxPrice = try container.decodeOptional(Double.self)

        // decode TIF
        tif = try container.decode(TimeInForce.self)

        // decode OcaGroup
        ocaGroup = try container.decodeOptional(String.self)

        // decode Account
        account = try container.decode(String.self)

        // decode OpenClose
        openClose = try container.decodeOptional(OpenClose.self)

        // decode Origin
        origin = try container.decode(IBOrder.Origin.self)

        // decode OrderRef
        orderRef = try container.decode(String.self)

        // decode ClientId
        clientID = try container.decode(Int.self)

        // decode PermId
        permID = try container.decode(Int.self)

        // decode OutsideRth
        outsideRth = try container.decode(Bool.self)

        // decode Hidden
        hidden = try container.decode(Bool.self)

        // decode DiscretionaryAmt
        discretionaryAmt = try container.decode(Double.self)

        // decode GoodAfterTime
        goodAfterTime = try container.decodeOptional(Date.self)

        // skip SharesAllocation
        _ = try container.decode(String.self)

        // decode FAParams
        faGroup = try container.decode(String.self)
        faMethod = try container.decode(String.self)
        faPercentage = try container.decode(String.self)

        if serverVersion < IBServerVersion.FA_PROFILE_DESUPPORT {
            _ = try container.decode(String.self)
        }

        // decode ModelCode
        if serverVersion >= IBServerVersion.MODELS_SUPPORT {
            modelCode = try container.decodeOptional(String.self)
        }

        // decode GoodTillDate
        goodTillDate = try container.decodeOptional(Date.self)

        // decode Rule80A
        rule80A = try container.decodeOptional(Rule80A.self)

        // decode PercentOffset
        percentOffset = try container.decodeOptional(Double.self)

        // decode SettlingFirm
        settlingFirm = try container.decodeOptional(String.self)

        // decode ShortSaleParams
        shortSaleSlot = try container.decodeOptional(IBOrder.Custody.self)

        designatedLocation = try container.decodeOptional(String.self)

        if serverVersion == IBServerVersion.SSHORTX_OLD {
            _ = try container.decode(Int.self)
        } else if version >= 23 {
            exemptCode = try container.decode(Int.self)
        }

        // decode AuctionStrategy
        auctionStrategy = try container.decodeOptional(IBOrder.AuctionStrategy.self)

        // decode BoxOrderParams
        startingPrice = try container.decodeOptional(Double.self)
        stockRefPrice = try container.decodeOptional(Double.self)
        delta = try container.decodeOptional(Double.self)

        // decode PegToStkOrVolOrderParams
        stockRangeLower = try container.decodeOptional(Double.self)
        stockRangeUpper = try container.decodeOptional(Double.self)

        // decode DisplaySize
        displaySize = try container.decodeOptional(Int.self)

        // decode BlockOrder
        blockOrder = try container.decode(Bool.self)

        // decode SweepToFill
        sweepToFill = try container.decode(Bool.self)

        // decode AllOrNone
        allOrNone = try container.decode(Bool.self)

        // decode MinQty
        minQty = try container.decodeOptional(Int.self)

        // decode OcaType
        ocaType = try container.decodeOptional(IBOrder.OCAType.self)

        // deprecated ETradeOnly
        _ = try container.decodeOptional(Bool.self)

        // deprecated FirmQuoteOnly
        _ = try container.decodeOptional(Bool.self)

        // deprecated NbboPriceCap
        _ = try container.decodeOptional(Double.self)

        // decode ParentId
        parentId = try container.decode(Int.self)

        // decode TriggerMethod
        triggerMethod = try container.decodeOptional(IBOrder.TriggerMethod.self)

        // decode VolOrderParams
        volatility = try container.decodeOptional(Double.self)
        volatilityType = try container.decodeOptional(IBOrder.VolaitilityType.self)
        deltaNeutralOrderType = try container.decodeOptional(String.self)
        deltaNeutralAuxPrice = try container.decodeOptional(Double.self)

        if version >= 27 && deltaNeutralOrderType != nil {
            deltaNeutralConId = try container.decodeOptional(Int.self)
            deltaNeutralSettlingFirm = try container.decodeOptional(String.self)
            deltaNeutralClearingAccount = try container.decodeOptional(String.self)
            deltaNeutralClearingIntent = try container.decodeOptional(String.self)
        }

        if version >= 31 && deltaNeutralOrderType != nil {
            deltaNeutralOpenClose = try container.decodeOptional(String.self)
            deltaNeutralShortSale = try container.decode(Bool.self)
            deltaNeutralShortSaleSlot = try container.decodeOptional(Int.self)
            deltaNeutralDesignatedLocation = try container.decodeOptional(String.self)
        }

        continuousUpdate = try container.decode(Bool.self)

        referencePriceType = try container.decodeOptional(IBOrder.ReferencePriceType.self)

        // decode TrailParams
        trailStopPrice = try container.decodeOptional(Double.self)

        if version >= 30 {
            trailingPercent = try container.decodeOptional(Double.self)
        }

        // decode BasisPoints
        basisPoints = try container.decodeOptional(Double.self)
        basisPointsType = try container.decodeOptional(Int.self)

        // decode ComboLegs
        contract.comboLegsDescrip = try container.decodeOptional(String.self)

        if version >= 29 {
            let comboLegsCount = try container.decode(Int.self)
            if comboLegsCount > 0 {
                contract.comboLegs = []
                for _ in 0 ..< comboLegsCount {
                    let leg = try container.decode(IBContract.ComboLeg.self)
                    contract.comboLegs?.append(leg)
                }
            }

            let orderComboLegsCount = try container.decode(Int.self)
            if orderComboLegsCount > 0 {
                orderComboLegs = []
                for _ in 0 ..< orderComboLegsCount {
                    let leg = try container.decode(IBOrder.ComboLeg.self)
                    orderComboLegs?.append(leg)
                }
            }
        }

        // decode SmartComboRoutingParams
        if version >= 26 {
            let smartComboRoutingParamsCount = try container.decode(Int.self)
            if smartComboRoutingParamsCount > 0 {
                smartComboRoutingParams = [:]
                for _ in 0 ..< smartComboRoutingParamsCount {
                    let key = try container.decode(String.self)
                    let value = try container.decode(String.self)
                    smartComboRoutingParams?[key] = value
                }
            }
        }

        // decode ScaleOrderParams
        scaleInitLevelSize = try container.decodeOptional(Int.self)
        scaleSubsLevelSize = try container.decodeOptional(Int.self)
        scalePriceIncrement = try container.decodeOptional(Double.self)

        if version >= 28 && scalePriceIncrement != Double.greatestFiniteMagnitude && scalePriceIncrement > 0.0 {
            scalePriceAdjustValue = try container.decode(Double.self)
            scalePriceAdjustInterval = try container.decode(Int.self)
            scaleProfitOffset = try container.decode(Double.self)
            scaleAutoReset = try container.decode(Bool.self)
            scaleInitPosition = try container.decode(Int.self)
            scaleInitFillQty = try container.decode(Int.self)
            scaleRandomPercent = try container.decode(Bool.self)
        }

        // decode HedgeParams
        if version >= 24 {
            hedgeType = try container.decodeOptional(HedgeType.self)
            if hedgeType != nil {
                hedgeParam = try container.decode(String.self)
            }
        }

        // decode OptOutSmartRouting
        if version >= 25 {
            optOutSmartRouting = try container.decode(Bool.self)
        }

        // decode ClearingParams
        clearingAccount = try container.decode(String.self)
        clearingIntent = try container.decode(ClearingIntent.self)

        // decode NotHeld
        if version >= 22 {
            notHeld = try container.decode(Bool.self)
        }

        // decode DeltaNeutral
        if version >= 20 {
            let deltaNeutralContractPresent = try container.decode(Bool.self)
            if deltaNeutralContractPresent {
                contract.deltaNeutralContract = try container.decode(IBContract.DeltaNeutral.self)
            }
        }

        // decode AlgoParams
        if version >= 21 {
            algoStrategy = try container.decodeOptional(AlgoStrategy.self)
            if algoStrategy != nil {
                let algoParamsCount = try container.decode(Int.self)
                if algoParamsCount > 0 {
                    algoParams = [:]
                    for _ in 0 ..< algoParamsCount {
                        let key = try container.decode(String.self)
                        let value = try container.decode(String.self)
                        algoParams?[key] = value
                    }
                }
            }
        }

        // decode Solicited
        if version >= 33 {
            solicited = try container.decode(Bool.self)
        }

        // decode WhatIfInfoAndCommission
        whatIf = try container.decode(Bool.self)

        // decode OrderStatus
        orderState = try container.decode(IBOrder.OrderState.self)

        // decode VolRandomizeFlags
        if version >= 34 {
            randomizeSize = try container.decode(Bool.self)
            randomizePrice = try container.decode(Bool.self)
        }

        // decode PegToBenchParams
        if serverVersion >= IBServerVersion.PEGGED_TO_BENCHMARK {
            if orderType == .PEG_BENCH {
                referenceContractId = try container.decode(Int.self)
                isPeggedChangeAmountDecrease = try container.decode(Bool.self)
                peggedChangeAmount = try container.decode(Double.self)
                referenceChangeAmount = try container.decode(Double.self)
                referenceExchangeId = try container.decodeOptional(String.self)
            }
        }

        // decode Conditions
        if serverVersion >= IBServerVersion.PEGGED_TO_BENCHMARK {
            let conditionsSize = try container.decode(Int.self)
            if conditionsSize > 0 {
                conditions = try container.decode(IBOrderCondition.self)
                conditionsIgnoreRth = try container.decode(Bool.self)
                conditionsCancelOrder = try container.decode(Bool.self)
            }
        }

        // decode AdjustedOrderParams
        if serverVersion >= IBServerVersion.PEGGED_TO_BENCHMARK {
            adjustedOrderType = try container.decodeOptional(String.self)
            triggerPrice = try container.decodeOptional(Double.self)
            trailStopPrice = try container.decodeOptional(Double.self)
            lmtPriceOffset = try container.decodeOptional(Double.self)
            adjustedStopPrice = try container.decodeOptional(Double.self)
            adjustedStopLimitPrice = try container.decodeOptional(Double.self)
            adjustedTrailingAmount = try container.decodeOptional(Double.self)
            adjustableTrailingUnit = try container.decodeOptional(Int.self)
        }

        // decode SoftDollarTier
        if serverVersion >= IBServerVersion.SOFT_DOLLAR_TIER {
            softDollarTier = try container.decode(SoftDollarTier.self)
        }

        // decode CashQty
        if serverVersion >= IBServerVersion.CASH_QTY {
            cashQuantity = try container.decodeOptional(Double.self)
        }

        // decode DontUseAutoPriceForHedge
        if serverVersion >= IBServerVersion.AUTO_PRICE_FOR_HEDGE {
            dontUseAutoPriceForHedge = try container.decode(Bool.self)
        }

        // decode IsOmsContainers
        if serverVersion >= IBServerVersion.ORDER_CONTAINER {
            isOmsContainer = try container.decode(Bool.self)
        }

        // decode DiscretionaryUpToLimitPrice
        if serverVersion >= IBServerVersion.D_PEG_ORDERS {
            discretionaryUpToLimitPrice = try container.decode(Bool.self)
        }

        // decode UsePriceMgmtAlgo
        if serverVersion >= IBServerVersion.PRICE_MGMT_ALGO {
            usePriceMgmtAlgo = try container.decodeOptional(Bool.self)
        }

        // decode Duration
        if serverVersion >= IBServerVersion.DURATION {
            duration = try container.decodeOptional(Int.self)
        }

        // decode PostToAts
        if serverVersion >= IBServerVersion.POST_TO_ATS {
            postToAts = try container.decodeOptional(Int.self)
        }

        // decode AutoCancelParent
        if serverVersion >= IBServerVersion.AUTO_CANCEL_PARENT {
            autoCancelParent = try container.decode(Bool.self)
        }

        // decode PegBestPegMidOrderAttributes
        if serverVersion >= IBServerVersion.PEGBEST_PEGMID_OFFSETS {
            minTradeQty = try container.decodeOptional(Int.self)
            minCompeteSize = try container.decodeOptional(Int.self)
            competeAgainstBestOffset = try container.decodeOptional(Double.self)
            midOffsetAtWhole = try container.decodeOptional(Double.self)
            midOffsetAtHalf = try container.decodeOptional(Double.self)
        }
    }
}
