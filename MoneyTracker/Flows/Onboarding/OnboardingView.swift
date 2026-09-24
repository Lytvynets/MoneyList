

import SwiftUI


struct OnboardingPage: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let onbImageName: String
    let headline: String
    let subtitle: String
}

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var pageIndex = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            onbImageName: "onb1",
            headline: "All your money,\nclearly in view",
            subtitle: "All your accounts, cards and cash\n— organized in one clean place,\nno spreadsheets required."
        ),
        OnboardingPage(
            onbImageName: "onb2",
            headline: "Always know what's\nsafe to spend",
            subtitle: "Money List works out what's left until\nthe end of the month, factoring in\nyour accounts and goals."
        ),
        OnboardingPage(
            onbImageName: "onb3",
            headline: "Your whole net\nworth in one place",
            subtitle: "Stocks, crypto, savings, or even\ncollectibles — add them\nand watch your wealth grow."
        ),
        OnboardingPage(
            onbImageName: "onb4",
            headline: "Your data\nbelongs to you",
            subtitle: "No bank logins required. Sync\nhappens only through your private\niCloud, protected by Face ID."
        )
    ]
    
    
    var body: some View {
        ZStack {
            FinoraColor.backgroundOnb.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    TabView(selection: $pageIndex) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            Image(page.onbImageName)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    if pageIndex < pages.count - 1 {
                        Button("Skip") { onComplete() }
                            .font(FinoraFont.bodyMedium)
                            .foregroundStyle(FinoraColor.textSecondary)
                            .padding()
                    }
                }
                
                Spacer()
                VStack(spacing: 20) {
                    
                    
                    VStack(spacing: 10) {
                        Text(pages[pageIndex].headline)
                            .font(FinoraFont.onboardingHeadline)
                            .foregroundStyle(FinoraColor.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(pages[pageIndex].subtitle)
                            .font(FinoraFont.body)
                            .foregroundStyle(FinoraColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, FinoraMetric.screenPadding)
                    .id(pageIndex)
                    .transition(.opacity)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == pageIndex ? FinoraColor.verdant : FinoraColor.divider)
                                .frame(width: index == pageIndex ? 24 : 8, height: 8)
                        }
                    }
                    
                    PrimaryButton(
                        title: pageIndex == pages.count - 1 ? "Get Started" : "Next",
                        gradient: pageIndex == pages.count - 1
                    ) {
                        if pageIndex == pages.count - 1 {
                            onComplete()
                        } else {
                            withAnimation { pageIndex += 1 }
                        }
                    }
                }
                .padding(.horizontal, FinoraMetric.screenPadding)
                .padding(.top, 48)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: FinoraMetric.sheetRadius, style: .continuous)
                        .fill(FinoraColor.surface2)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            
        }
        .animation(.easeInOut, value: pageIndex)
    }
}


#Preview {
    OnboardingView(onComplete: {})
}
