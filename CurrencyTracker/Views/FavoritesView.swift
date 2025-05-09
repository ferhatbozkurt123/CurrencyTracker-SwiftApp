import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = CurrencyViewModel()
    @AppStorage("favoriteCurrencies") private var favoriteCurrencyCodes: String = ""
    
    private var favoriteCurrencies: [Currency] {
        let codes = favoriteCurrencyCodes.split(separator: ",").map(String.init)
        return viewModel.currencies.filter { codes.contains($0.majorCurrency) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                if favoriteCurrencies.isEmpty {
                    emptyStateView
                } else {
                    currencyList
                }
            }
            .navigationTitle("Favoriler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
        }
        .task {
            await viewModel.fetchCurrencies()
        }
    }
    
    private var currencyList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(favoriteCurrencies) { currency in
                    CurrencyRow(
                        currency: currency,
                        isFavorite: true
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            removeFavorite(currency)
                        } label: {
                            Label("Favorilerden Çıkar", systemImage: "star.slash.fill")
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.fetchCurrencies()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.accent)
            
            Text("Henüz favori para biriminiz yok")
                .font(.headline)
            
            Text("Ana ekrandan para birimlerini favorilere ekleyebilirsiniz")
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.fetchCurrencies()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .semibold))
        }
    }
    
    private func removeFavorite(_ currency: Currency) {
        var codes = favoriteCurrencyCodes.split(separator: ",").map(String.init)
        if let index = codes.firstIndex(of: currency.majorCurrency) {
            codes.remove(at: index)
            favoriteCurrencyCodes = codes.joined(separator: ",")
        }
    }
}

#if DEBUG
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
#endif 