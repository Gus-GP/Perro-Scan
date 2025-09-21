//
//  LoadingView.swift
//  PerroScan
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated dog paw prints
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "pawprint.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            // Loading message with animated dots
            Text(message + dots)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear {
            isAnimating = true
            startDotsAnimation()
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    private func startDotsAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                if dots.count < 3 {
                    dots += "."
                } else {
                    dots = ""
                }
            }
            
            if !isAnimating {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    LoadingView(message: "Analyzing image")
}

