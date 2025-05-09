import Foundation
import SwiftUI

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

class CurrencyViewModel: ObservableObject {
    @Published var currencies: [Currency] = []
    @Published var historicalData: [String: [HistoricalRate]] = [:]
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var historicalLoadingState: LoadingState = .idle
    
    private let baseURL = "https://api.yapikredi.com.tr/api/investmentrates/v1"
    private let tcmbURL = "https://www.tcmb.gov.tr/kurlar/today.xml"
    private var lastUpdateDate: Date?
    
    // UserDefaults kullanarak ayarları saklayalım
    private let defaults = UserDefaults.standard
    
    var updateInterval: Double {
        get { defaults.double(forKey: "updateInterval") }
        set { defaults.set(newValue, forKey: "updateInterval") }
    }
    
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: "notificationsEnabled") }
        set { defaults.set(newValue, forKey: "notificationsEnabled") }
    }
    
    var notificationThreshold: Double {
        get { defaults.double(forKey: "notificationThreshold") }
        set { defaults.set(newValue, forKey: "notificationThreshold") }
    }
    
    init() {
        // Varsayılan değerleri ayarla
        if updateInterval == 0 {
            updateInterval = 900 // 15 dakika
        }
        if notificationThreshold == 0 {
            notificationThreshold = 1.0 // %1
        }
    }
    
    @MainActor
    func fetchCurrencies() async {
        // Eğer son güncelleme üzerinden belirlenen süre geçmediyse güncelleme yapma
        if let lastUpdate = lastUpdateDate,
           Date().timeIntervalSince(lastUpdate) < updateInterval {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let url = URL(string: tcmbURL) else {
                throw NetworkError.invalidResponse
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let parser = TCMBParser()
            let tcmbCurrencies = parser.parse(data: data)
            
            // Sadece geçerli kurları filtrele ve dönüştür
            var processedCurrencies = tcmbCurrencies
                .filter { currency in
                    currency.buyRate > 0 && currency.sellRate > 0
                }
                .map { currency -> Currency in
                    let effectiveRates = currency.effectiveBuyRate > 0 && currency.effectiveSellRate > 0
                    
                    let buyRate = effectiveRates ? currency.effectiveBuyRate : currency.buyRate
                    let sellRate = effectiveRates ? currency.effectiveSellRate : currency.sellRate
                    let averageRate = (buyRate + sellRate) / 2
                    
                    return Currency(
                        majorCurrency: currency.code,
                        minorCurrency: "TRY",
                        name: formatCurrencyName(currency.name, unit: currency.unit),
                        buyRate: buyRate,
                        sellRate: sellRate,
                        averageRate: averageRate,
                        changeRatio: calculateChangeRatio(
                            current: sellRate,
                            previous: currency.previousDaySellRate ?? 0
                        ),
                        previousDayBuyRate: currency.previousDayBuyRate ?? 0,
                        previousDaySellRate: currency.previousDaySellRate ?? 0,
                        previousDayAverageRate: ((currency.previousDayBuyRate ?? 0) + (currency.previousDaySellRate ?? 0)) / 2
                    )
                }
            
            // TL kurunu ekle
            let tryCurrency = Currency(
                majorCurrency: "TRY",
                minorCurrency: "TRY",
                name: "Türk Lirası",
                buyRate: 1.0,
                sellRate: 1.0,
                averageRate: 1.0,
                changeRatio: 0.0,
                previousDayBuyRate: 1.0,
                previousDaySellRate: 1.0,
                previousDayAverageRate: 1.0
            )
            
            processedCurrencies.append(tryCurrency)
            currencies = processedCurrencies.sorted { $0.buyRate > $1.buyRate }
            
            // Bildirim kontrolü
            if notificationsEnabled {
                NotificationManager.shared.checkAndScheduleNotifications(
                    currencies: currencies,
                    threshold: notificationThreshold
                )
            }
            
            lastUpdateDate = Date()
            
        } catch {
            errorMessage = "Veri alınamadı: \(error.localizedDescription)"
            print("Hata: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func fetchHistoricalData(for currencyPair: String, days: Int = 30) async {
        historicalLoadingState = .loading
        
        // Önce cache'i kontrol et
        if let cachedData = await CacheManager.shared.getFromCache(key: currencyPair) {
            historicalData[currencyPair] = cachedData
            historicalLoadingState = .loaded
            return
        }
        
        let calendar = Calendar.current
        var historicalRates: [HistoricalRate] = []
        
        // Şimdilik test verileri oluşturalım (API geçmişe dönük veri sağlamıyor)
        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // Rastgele değişimler ile test verisi oluştur
            let baseRate = currencies.first(where: { "\($0.majorCurrency)/\($0.minorCurrency)" == currencyPair })
            if let currency = baseRate {
                let randomChange = Double.random(in: -0.02...0.02)
                let historicalRate = HistoricalRate(
                    date: date,
                    buyRate: currency.buyRate * (1 + randomChange),
                    sellRate: currency.sellRate * (1 + randomChange),
                    averageRate: currency.averageRate * (1 + randomChange)
                )
                historicalRates.append(historicalRate)
            }
        }
        
        let sortedRates = historicalRates.sorted(by: { $0.date < $1.date })
        historicalData[currencyPair] = sortedRates
        await CacheManager.shared.saveToCache(key: currencyPair, data: sortedRates)
        historicalLoadingState = .loaded
    }
    
    private func getCurrencyPairName(major: String, minor: String) -> String {
        let currencyNames = [
            "USD": "Amerikan Doları",
            "EUR": "Euro",
            "GBP": "İngiliz Sterlini",
            "JPY": "Japon Yeni",
            "CHF": "İsviçre Frangı",
            "TL": "Türk Lirası",
            "XAU": "Altın"
        ]
        
        let majorName = currencyNames[major] ?? major
        let minorName = currencyNames[minor] ?? minor
        
        return "\(majorName)/\(minorName)"
    }
    
    private func formatCurrencyName(_ name: String, unit: Int) -> String {
        if unit > 1 {
            return "\(unit) \(name)"
        }
        return name
    }
    
    private func calculateChangeRatio(current: Double, previous: Double) -> Double {
        guard previous > 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    
    // Bildirim izinlerini kontrol et
    func checkNotificationPermissions() {
        Task {
            do {
                let authorized = try await NotificationManager.shared.requestAuthorization()
                await MainActor.run {
                    if !authorized {
                        notificationsEnabled = false
                    }
                }
            } catch {
                print("Bildirim izni alınamadı: \(error.localizedDescription)")
                await MainActor.run {
                    notificationsEnabled = false
                }
            }
        }
    }
}

enum NetworkError: Error {
    case invalidResponse
    case serverError(statusCode: Int)
} 