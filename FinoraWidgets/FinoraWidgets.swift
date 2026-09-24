

import WidgetKit
import SwiftUI


private enum WColor {
    static let background = Color(red: 0x0B / 255, green: 0x1F / 255, blue: 0x1A / 255)
    static let surface = Color(red: 0x14 / 255, green: 0x2F / 255, blue: 0x27 / 255)
    static let verdant = Color(red: 0x34 / 255, green: 0xB2 / 255, blue: 0x7F / 255)
    static let coral = Color(red: 0xF2 / 255, green: 0x78 / 255, blue: 0x6A / 255)
    static let textPrimary = Color(red: 0xF5 / 255, green: 0xF7 / 255, blue: 0xF2 / 255)
    static let textSecondary = Color(red: 0x8F / 255, green: 0xA3 / 255, blue: 0x98 / 255)

    static func hex(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        return Color(
            red: Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >> 8) / 255,
            blue: Double(rgb & 0x0000FF) / 255
        )
    }
}


struct FinoraTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct FinoraTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinoraTimelineEntry {
        FinoraTimelineEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FinoraTimelineEntry) -> Void) {
        completion(FinoraTimelineEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinoraTimelineEntry>) -> Void) {
        let entry = FinoraTimelineEntry(date: .now, snapshot: WidgetSnapshot.load())
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}


struct FinoraSafeToSpendWidget: Widget {
    let kind = "FinoraSafeToSpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinoraTimelineProvider()) { entry in
            FinoraWidgetRootView(entry: entry)
                .containerBackground(WColor.surface, for: .widget)
        }
        .configurationDisplayName("Safe to Spend")
        .description("See your safe-to-spend balance, budget and recent activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct FinoraWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FinoraSafeToSpendWidget()
    }
}


struct FinoraWidgetRootView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FinoraTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium: MediumWidgetView(snapshot: entry.snapshot)
        default: LargeWidgetView(snapshot: entry.snapshot)
        }
    }
}


struct SmallWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "leaf.fill").foregroundStyle(WColor.verdant)
            Spacer()
            Text("Safe to spend").font(.caption2).foregroundStyle(WColor.textSecondary)
            Text(snapshot.safeToSpendDisplay).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(WColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Safe to spend").font(.caption2).foregroundStyle(WColor.textSecondary)
                Text(snapshot.safeToSpendDisplay).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(WColor.textPrimary)
                Spacer(minLength: 8)
                Text("Budget").font(.caption2).foregroundStyle(WColor.textSecondary)
                Text("\(snapshot.budgetSpentDisplay) / \(snapshot.budgetLimitDisplay)").font(.caption).foregroundStyle(WColor.textPrimary)
                progressBar
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent").font(.caption2).foregroundStyle(WColor.textSecondary)
                ForEach(snapshot.recentTransactions.prefix(2)) { transaction in
                    HStack {
                        Text(transaction.title).font(.caption).foregroundStyle(WColor.textPrimary).lineLimit(1)
                        Spacer()
                        Text(transaction.amountDisplay).font(.caption2).foregroundStyle(transaction.isExpense ? WColor.coral : WColor.verdant)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(WColor.textSecondary.opacity(0.2))
                Capsule().fill(snapshot.budgetProgress > 0.9 ? WColor.coral : WColor.verdant)
                    .frame(width: geo.size.width * snapshot.budgetProgress)
            }
        }
        .frame(height: 5)
    }
}


struct LargeWidgetView: View {
    let snapshot: WidgetSnapshot

    private var total: Double { snapshot.categories.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 2) {
                Text("Safe to spend").font(.caption).foregroundStyle(WColor.textSecondary)
                Text(snapshot.safeToSpendDisplay).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(WColor.textPrimary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                donut.frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(snapshot.categories) { category in
                        HStack(spacing: 6) {
                            Circle().fill(WColor.hex(category.colorHex)).frame(width: 6, height: 6)
                            Text(category.name).font(.caption2).foregroundStyle(WColor.textPrimary).lineLimit(1)
                            Spacer()
                            Text(percent(category.amount)).font(.caption2).foregroundStyle(WColor.textSecondary)
                        }
                    }
                }
            }

            Divider().overlay(WColor.textSecondary.opacity(0.2))

            VStack(alignment: .leading, spacing: 6) {
                Text("Recent transactions").font(.caption2).foregroundStyle(WColor.textSecondary)
                ForEach(snapshot.recentTransactions.prefix(4)) { transaction in
                    HStack {
                        Text(transaction.title).font(.caption).foregroundStyle(WColor.textPrimary).lineLimit(1)
                        Spacer()
                        Text(transaction.amountDisplay).font(.caption).foregroundStyle(transaction.isExpense ? WColor.coral : WColor.verdant)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var donut: some View {
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                Circle()
                    .trim(from: slice.start, to: slice.end)
                    .stroke(WColor.hex(slice.colorHex), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private var slices: [(start: CGFloat, end: CGFloat, colorHex: String)] {
        guard total > 0 else { return [] }
        var cursor: CGFloat = 0
        return snapshot.categories.map { category in
            let fraction = CGFloat(category.amount / total)
            let slice = (cursor, cursor + fraction, category.colorHex)
            cursor += fraction
            return slice
        }
    }

    private func percent(_ amount: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }
}

#Preview("Small", as: .systemSmall) {
    FinoraSafeToSpendWidget()
} timeline: {
    FinoraTimelineEntry(date: .now, snapshot: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    FinoraSafeToSpendWidget()
} timeline: {
    FinoraTimelineEntry(date: .now, snapshot: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    FinoraSafeToSpendWidget()
} timeline: {
    FinoraTimelineEntry(date: .now, snapshot: .placeholder)
}
