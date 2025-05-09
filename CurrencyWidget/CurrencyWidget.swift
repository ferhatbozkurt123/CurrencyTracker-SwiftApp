import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CurrencyEntry {
        CurrencyEntry(date: Date(), currencies: [
            Currency(
                majorCurrency: "USD",
                minorCurrency: "TRY",
                name: "Amerikan Doları",
                buyRate: 31.8450,
                sellRate: 31.9850,
                averageRate: 31.9150,
                changeRatio: 0.25,
                previousDayBuyRate: 31.7450,
                previousDaySellRate: 31.8850,
                previousDayAverageRate: 31.8150
            )
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrencyEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            do {
                let currencies = try await fetchCurrencies()
                let entry = CurrencyEntry(date: .now, currencies: currencies)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
                completion(timeline)
            }
        }
    }
    
    private func fetchCurrencies() async throws -> [Currency] {
        guard let url = URL(string: "https://www.tcmb.gov.tr/kurlar/today.xml") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = TCMBParser()
        let tcmbCurrencies = parser.parse(data: data)
        
        return tcmbCurrencies
            .filter { $0.buyRate > 0 && $0.sellRate > 0 }
            .prefix(3)
            .map { currency -> Currency in
                let effectiveRates = currency.effectiveBuyRate > 0 && currency.effectiveSellRate > 0
                let buyRate = effectiveRates ? currency.effectiveBuyRate : currency.buyRate
                let sellRate = effectiveRates ? currency.effectiveSellRate : currency.sellRate
                
                return Currency(
                    majorCurrency: currency.code,
                    minorCurrency: "TRY",
                    name: formatCurrencyName(currency.name, unit: currency.unit),
                    buyRate: buyRate,
                    sellRate: sellRate,
                    averageRate: (buyRate + sellRate) / 2,
                    changeRatio: 0,
                    previousDayBuyRate: currency.previousDayBuyRate ?? 0,
                    previousDaySellRate: currency.previousDaySellRate ?? 0,
                    previousDayAverageRate: ((currency.previousDayBuyRate ?? 0) + (currency.previousDaySellRate ?? 0)) / 2
                )
            }
            .map { $0 }
    }
    
    private func formatCurrencyName(_ name: String, unit: Int) -> String {
        if unit > 1 {
            return "\(unit) \(name)"
        }
        return name
    }
}

struct CurrencyEntry: TimelineEntry {
    let date: Date
    let currencies: [Currency]
}

struct CurrencyWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            Text("Not supported")
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        if let currency = entry.currencies.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(currency.majorCurrency)
                        .font(.headline)
                    Spacer()
                    Text(currency.formattedChangeRatio)
                        .font(.caption)
                        .foregroundColor(currency.isPositiveChange ? .green : .red)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Alış:")
                            .font(.caption2)
                        Spacer()
                        Text(String(format: "%.4f", currency.buyRate))
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Satış:")
                            .font(.caption2)
                        Spacer()
                        Text(String(format: "%.4f", currency.sellRate))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack {
            ForEach(entry.currencies.prefix(3)) { currency in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currency.majorCurrency)
                            .font(.headline)
                        Spacer()
                        Text(currency.formattedChangeRatio)
                            .font(.caption)
                            .foregroundColor(currency.isPositiveChange ? .green : .red)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Alış:")
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.4f", currency.buyRate))
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Satış:")
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.4f", currency.sellRate))
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                if currency != entry.currencies.last {
                    Divider()
                }
            }
        }
        .padding()
    }
}

@main
struct CurrencyWidget: Widget {
    let kind: String = "CurrencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CurrencyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Döviz Kurları")
        .description("Güncel döviz kurlarını gösterir")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
} 