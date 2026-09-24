

import Foundation

enum PriceSyncError: LocalizedError {
    case unknownTicker
    case badURL
    case missingPrice
    case missingAPIKey
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .unknownTicker:
            return "Unrecognized ticker. Try the plain symbol, e.g. BTC or ETH."
        case .badURL:
            return "Couldn't build the request URL."
        case .missingPrice:
            return "No price was returned for this symbol."
        case .missingAPIKey:
            return "Add a free Twelve Data API key in AppDefaults.swift to enable stock prices."
        case .network(let error):
            return error.localizedDescription
        }
    }
}

enum PriceSyncService {

    private static let coinGeckoIDs: [String: String] = [
        "BTC": "bitcoin", "ETH": "ethereum", "SOL": "solana", "XRP": "ripple",
        "ADA": "cardano", "DOGE": "dogecoin", "DOT": "polkadot", "MATIC": "matic-network",
        "LTC": "litecoin", "BNB": "binancecoin", "AVAX": "avalanche-2", "LINK": "chainlink",
        "USDT": "tether", "USDC": "usd-coin", "TRX": "tron", "TON": "the-open-network",
        "SHIB": "shiba-inu", "ATOM": "cosmos", "XLM": "stellar", "NEAR": "near"
    ]

    static func fetchCryptoPrice(ticker: String, vsCurrency: String) async throws -> Decimal {
        let id = coinGeckoIDs[ticker.uppercased()] ?? ticker.lowercased()
        let vs = vsCurrency.lowercased()
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(id)&vs_currencies=\(vs)") else {
            throw PriceSyncError.badURL
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            guard let price = decoded[id]?[vs] else { throw PriceSyncError.missingPrice }
            return Decimal(price)
        } catch let error as PriceSyncError {
            throw error
        } catch {
            throw PriceSyncError.network(error)
        }
    }

    static func fetchStockPrice(ticker: String) async throws -> Decimal {
        guard !AppDefaults.twelveDataAPIKey.isEmpty else { throw PriceSyncError.missingAPIKey }
        guard let url = URL(string: "https://api.twelvedata.com/price?symbol=\(ticker)&apikey=\(AppDefaults.twelveDataAPIKey)") else {
            throw PriceSyncError.badURL
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Response: Decodable { let price: String? }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let priceString = decoded.price, let price = Decimal(string: priceString) else {
                throw PriceSyncError.missingPrice
            }
            return price
        } catch let error as PriceSyncError {
            throw error
        } catch {
            throw PriceSyncError.network(error)
        }
    }

    static func fetchPrice(for asset: Asset) async throws -> Decimal {
        guard let ticker = asset.ticker, !ticker.isEmpty else { throw PriceSyncError.unknownTicker }
        switch asset.type {
        case .crypto: return try await fetchCryptoPrice(ticker: ticker, vsCurrency: asset.currencyCode)
        case .stock: return try await fetchStockPrice(ticker: ticker)
        case .collectible: throw PriceSyncError.unknownTicker
        }
    }
}
