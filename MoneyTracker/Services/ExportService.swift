

import Foundation

enum ExportService {

    static func csv(for transactions: [Transaction]) -> String {
        var rows = ["Date,Type,Category,Account,Amount,Currency,Note"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let date = formatter.string(from: transaction.date)
            let type = transaction.type.displayName
            let category = transaction.category?.name ?? "—"
            let account = transaction.account?.name ?? "—"
            let amount = "\(transaction.amount)"
            let currency = transaction.account?.currencyCode ?? "USD"
            let note = (transaction.note ?? "").replacingOccurrences(of: ",", with: ";")
            rows.append("\(date),\(type),\(category),\(account),\(amount),\(currency),\(note)")
        }
        return rows.joined(separator: "\n")
    }


    static func writeTemporaryFile(csv: String, filename: String = "MoneyList-Export.csv") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Money List: export failed — \(error)")
            return nil
        }
    }
}
