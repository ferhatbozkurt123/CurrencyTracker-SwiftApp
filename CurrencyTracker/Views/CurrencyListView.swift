import SwiftUI

struct CurrencyListView: View {
    @ObservedObject var viewModel: CurrencyViewModel
    @State private var selectedCurrency: Currency?
    @State private var showingChart = false
    @State private var searchText = ""
    @AppStorage("favoriteCurrencies") private var favoriteCurrencyCodes: String = ""
    
    private var filteredCurrencies: [Currency] {
        let filtered = viewModel.currencies.filter { $0.majorCurrency != "TRY" }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.majorCurrency.localizedCaseInsensitiveContains(searchText) ||
            $0.minorCurrency.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Arama çubuğu
                    searchBar
                        .padding(.horizontal, Theme.padding)
                        .padding(.vertical, 12)
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if filteredCurrencies.isEmpty {
                        emptyStateView
                    } else {
                        currencyList
                    }
                }
            }
            .navigationTitle("Döviz Kurları")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .sheet(isPresented: $showingChart) {
                if let currency = selectedCurrency {
                    CurrencyChartView(
                        currency: currency,
                        historicalData: viewModel.historicalData[currency.pairName] ?? [],
                        viewModel: viewModel
                    )
                }
            }
        }
        .task {
            await viewModel.fetchCurrencies()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.secondaryText)
                .font(.system(size: 17, weight: .medium))
            
            TextField("Para birimi ara...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .accentColor(Theme.primary)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.secondaryText)
                        .font(.system(size: 17))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: Theme.shadowColor.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
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
    }
    
    private var currencyList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredCurrencies) { currency in
                    CurrencyRow(
                        currency: currency,
                        isFavorite: isFavorite(currency)
                    )
                    .onTapGesture {
                        selectedCurrency = currency
                        showingChart = true
                    }
                    .contextMenu {
                        Button {
                            toggleFavorite(currency)
                        } label: {
                            Label(
                                isFavorite(currency) ? "Favorilerden Çıkar" : "Favorilere Ekle",
                                systemImage: isFavorite(currency) ? "star.slash.fill" : "star.fill"
                            )
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
    
    private var loadingView: some View {
        VStack(spacing: Theme.padding) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.primary)
            
            Text("Veriler güncelleniyor...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Theme.secondaryText)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.padding) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 45))
                .foregroundColor(Theme.secondaryText)
                .padding()
                .background(
                    Circle()
                        .fill(Theme.cardBackground)
                        .shadow(
                            color: Theme.shadowColor.opacity(0.05),
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                )
            
            Text("Sonuç bulunamadı")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.text)
            
            Text("Farklı bir arama yapmayı deneyin")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.padding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
    
    // Favori işlemleri
    private func isFavorite(_ currency: Currency) -> Bool {
        let codes = favoriteCurrencyCodes.split(separator: ",").map(String.init)
        return codes.contains(currency.majorCurrency)
    }
    
    private func toggleFavorite(_ currency: Currency) {
        var codes = favoriteCurrencyCodes.split(separator: ",").map(String.init)
        
        if let index = codes.firstIndex(of: currency.majorCurrency) {
            codes.remove(at: index)
        } else {
            codes.append(currency.majorCurrency)
        }
        
        favoriteCurrencyCodes = codes.joined(separator: ",")
    }
}

#if DEBUG
struct CurrencyListView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyListView(viewModel: CurrencyViewModel())
    }
}
#endif 