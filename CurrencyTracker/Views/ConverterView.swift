import SwiftUI

struct ConverterView: View {
    @StateObject private var viewModel = CurrencyViewModel()
    @State private var amount: String = ""
    @State private var fromCurrency: Currency?
    @State private var toCurrency: Currency?
    
    private var convertedAmount: Double {
        guard let from = fromCurrency,
              let to = toCurrency,
              let inputAmount = Double(amount) else { return 0 }
        
        let rate = to.buyRate / from.buyRate
        return inputAmount * rate
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Miktar girişi
                TextField("Miktar", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Para birimi seçicileri
                HStack {
                    CurrencyPickerView(
                        selectedCurrency: $fromCurrency,
                        currencies: viewModel.currencies,
                        title: "Kaynak"
                    )
                    
                    Image(systemName: "arrow.right")
                        .font(.title2)
                    
                    CurrencyPickerView(
                        selectedCurrency: $toCurrency,
                        currencies: viewModel.currencies,
                        title: "Hedef"
                    )
                }
                .padding()
                
                // Sonuç
                if fromCurrency != nil && toCurrency != nil {
                    VStack(spacing: 8) {
                        Text("Sonuç")
                            .font(.headline)
                        Text(String(format: "%.2f %@", convertedAmount, toCurrency?.majorCurrency ?? ""))
                            .font(.title)
                            .bold()
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .shadow(radius: Theme.shadowRadius)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Döviz Çevirici")
            .task {
                await viewModel.fetchCurrencies()
            }
        }
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency?
    let currencies: [Currency]
    let title: String
    
    var body: some View {
        Menu {
            ForEach(currencies) { currency in
                Button {
                    selectedCurrency = currency
                } label: {
                    Text(currency.displayName)
                }
            }
        } label: {
            HStack {
                Text(selectedCurrency?.majorCurrency ?? title)
                    .foregroundColor(selectedCurrency == nil ? .gray : .primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(radius: Theme.shadowRadius)
        }
    }
}

#if DEBUG
struct ConverterView_Previews: PreviewProvider {
    static var previews: some View {
        ConverterView()
    }
}
#endif 