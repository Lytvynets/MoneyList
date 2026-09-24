

import SwiftUI

private enum MainTab {
    case overview, transactions, analytics, profile
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .overview
    @State private var showAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            FinoraColor.screenBackground.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .overview: OverviewView()
                case .transactions: TransactionsListView()
                case .analytics: AnalyticsView()
                case .profile: ProfileView()
                }
            }

            tabBar
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.overview, filled: "house.fill", outline: "house", label: "Overview")
            tabButton(.transactions, filled: "list.bullet.rectangle.fill", outline: "list.bullet", label: "Transactions")

            Button { showAddTransaction = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: FinoraMetric.fabSize, height: FinoraMetric.fabSize)
                    .background(FinoraColor.brandGradient)
                    .clipShape(Circle())
                    .shadow(color: FinoraColor.verdant.opacity(0.35), radius: 10, y: 4)
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)

            tabButton(.analytics, filled: "chart.pie.fill", outline: "chart.pie", label: "Analytics")
            tabButton(.profile, filled: "person.fill", outline: "person", label: "Profile")
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(FinoraColor.divider).frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: MainTab, filled: String, outline: String, label: String) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? filled : outline)
                    .font(.system(size: 20))
                Text(label).font(FinoraFont.micro)
            }
            .foregroundStyle(selectedTab == tab ? FinoraColor.verdant : FinoraColor.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}
