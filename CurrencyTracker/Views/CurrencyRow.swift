import SwiftUI

struct CurrencyRow: View {
    let currency: Currency
    let isFavorite: Bool
    @State private var isPressed = false
    
    private var currencyPairName: String {
        "\(currency.majorCurrency)/TL"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.padding) {
                // Para birimi ikonu
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.primary.opacity(0.2),
                                    Theme.secondary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Text(currency.majorCurrency)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primary)
                }
                
                // Para birimi bilgileri
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(currency.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.accent)
                                .shadow(color: Theme.accent.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    Text(currency.name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: currency.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(currency.formattedChangeRatio)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(currency.isPositiveChange ? Theme.positive : Theme.negative)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (currency.isPositiveChange ? Theme.positive : Theme.negative)
                            .opacity(0.1)
                            .cornerRadius(6)
                    )
                }
                
                Spacer()
                
                // Alış-Satış Fiyatları
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Alış:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                        Text(String(format: "%.4f", currency.buyRate))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primary)
                            .frame(minWidth: 85, alignment: .trailing)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Satış:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                        Text(String(format: "%.4f", currency.sellRate))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.secondary)
                            .frame(minWidth: 85, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: Theme.shadowColor.opacity(0.08),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, Theme.padding)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            hapticFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
} 