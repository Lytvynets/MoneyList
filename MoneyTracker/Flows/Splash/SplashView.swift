

import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var ringProgress: CGFloat = 0
    @State private var glyphScale: CGFloat = 0.4
    @State private var glyphRotation: Double = -70
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12
    @State private var tickerOpacity: Double = 0
    @State private var tickerValue: Double = 0
    @State private var exitScale: CGFloat = 1
    @State private var exitOpacity: Double = 1

    var body: some View {
        ZStack {
            FinoraColor.background.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(FinoraColor.brassGold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 160, height: 160)

                    Image("logo2")
                        .resizable()
                        .frame(width: 158, height: 158)
                        .clipShape(.circle)
                        .scaledToFit()
                        .scaleEffect(glyphScale)
                        .rotation3DEffect(.degrees(glyphRotation), axis: (x: 0, y: 1, z: 0))
                }

                VStack(spacing: 8) {
                    Text("Money List")
                        .font(FinoraFont.splashWordmark)
                        .foregroundStyle(FinoraColor.textPrimary)
                        .opacity(wordmarkOpacity)
                        .offset(y: wordmarkOffset)

                    Text(tickerValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(FinoraFont.amount(14, weight: .medium))
                        .foregroundStyle(FinoraColor.verdant)
                        .contentTransition(.numericText(value: tickerValue))
                        .opacity(tickerOpacity)
                        .monospacedDigit()
                }
            }
            .scaleEffect(exitScale)
        }
        .opacity(exitOpacity)
        .onAppear(perform: runStoryboard)
    }

    private func runStoryboard() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            ringProgress = 1
            glyphScale = 1.06
        }
        withAnimation(.easeOut(duration: 0.25).delay(0.55)) {
            glyphScale = 1.0
        }
        withAnimation(.easeInOut(duration: 0.3).delay(0.6)) {
            glyphRotation = 0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            wordmarkOpacity = 1
            wordmarkOffset = 0
        }

        withAnimation(.easeOut(duration: 0.25).delay(1.1)) {
            tickerOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.1)) {
            tickerValue = 12480
        }
        withAnimation(.easeInOut(duration: 0.45).delay(2.7)) {
            exitScale = 0.92
        }
        withAnimation(.easeInOut(duration: 0.45).delay(2.85)) {
            exitOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
