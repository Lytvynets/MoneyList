

import Foundation
internal import Combine

@MainActor
final class CurrencyExchangeService: ObservableObject {
    @Published private(set) var ratesFromUSD: [String: Decimal] = [:]
    @Published private(set) var lastUpdated: Date?

    private let ratesKey = "finora.exchangeRates.v2"
    private let timestampKey = "finora.exchangeRates.timestamp.v2"
    private let refreshInterval: TimeInterval = 60 * 60 * 12 

    init() {
        loadFromCache()
    }

    func refreshIfNeeded() async {
        if let lastUpdated, Date().timeIntervalSince(lastUpdated) < refreshInterval, !ratesFromUSD.isEmpty {
            return
        }
        guard let url = URL(string: "https://api.frankfurter.dev/v2/rates?base=USD") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([FrankfurterV2Rate].self, from: data)
            var rates: [String: Decimal] = [:]
            for entry in decoded {
                rates[entry.quote] = Decimal(entry.rate)
            }
            rates["USD"] = 1
            ratesFromUSD = rates
            lastUpdated = .now
            saveToCache()
        } catch {
            print("Money List: exchange rate refresh failed — \(error)")
        }
    }

    func convert(_ amount: Decimal, from: String, to: String) -> Decimal {
        guard from != to else { return amount }
        guard let fromRate = ratesFromUSD[from], let toRate = ratesFromUSD[to], fromRate > 0 else {
            return amount
        }
        return amount / fromRate * toRate
    }

    private func loadFromCache() {
        guard
            let data = UserDefaults.standard.data(forKey: ratesKey),
            let decoded = try? JSONDecoder().decode([String: Decimal].self, from: data)
        else { return }
        ratesFromUSD = decoded
        lastUpdated = UserDefaults.standard.object(forKey: timestampKey) as? Date
    }

    private func saveToCache() {
        guard let data = try? JSONEncoder().encode(ratesFromUSD) else { return }
        UserDefaults.standard.set(data, forKey: ratesKey)
        UserDefaults.standard.set(lastUpdated, forKey: timestampKey)
    }
}


private struct FrankfurterV2Rate: Decodable {
    let quote: String
    let rate: Double
}
