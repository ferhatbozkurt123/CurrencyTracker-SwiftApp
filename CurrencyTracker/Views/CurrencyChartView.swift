import SwiftUI
import Charts

struct CurrencyChartView: View {
    let currency: Currency
    let historicalData: [HistoricalRate]
    @ObservedObject var viewModel: CurrencyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var selectedPoint: HistoricalRate?
    
    private enum ChartPeriod: String, CaseIterable {
        case week = "1 Hafta"
        case month = "1 Ay"
        case threeMonths = "3 Ay"
        case year = "1 Yıl"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Özet Kart
                    summaryCard
                    
                    // Dönem Seçici
                    periodPicker
                    
                    // Grafik
                    chartView
                    
                    // Detay Tablosu
                    detailsTable
                }
                .padding()
            }
            .navigationTitle("\(currency.majorCurrency)/\(currency.minorCurrency)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchHistoricalData(for: "\(currency.majorCurrency)/\(currency.minorCurrency)", days: selectedPeriod.days)
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(currency.displayName)
                    .font(.headline)
                Spacer()
                Text(currency.formattedChangeRatio)
                    .font(.subheadline)
                    .foregroundColor(currency.isPositiveChange ? Theme.positive : Theme.negative)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (currency.isPositiveChange ? Theme.positive : Theme.negative)
                            .opacity(0.1)
                            .cornerRadius(6)
                    )
            }
            
            Divider()
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Alış")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                    Text(String(format: "%.4f", currency.buyRate))
                        .font(.title3)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Satış")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                    Text(String(format: "%.4f", currency.sellRate))
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(radius: Theme.shadowRadius)
    }
    
    private var periodPicker: some View {
        Picker("Dönem", selection: $selectedPeriod) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { newValue in
            Task {
                await viewModel.fetchHistoricalData(
                    for: "\(currency.majorCurrency)/\(currency.minorCurrency)",
                    days: newValue.days
                )
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            ForEach(historicalData) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Kur", point.averageRate)
                )
                .foregroundStyle(Theme.primary.gradient)
                
                AreaMark(
                    x: .value("Tarih", point.date),
                    y: .value("Kur", point.averageRate)
                )
                .foregroundStyle(Theme.primary.opacity(0.1).gradient)
            }
            
            if let selected = selectedPoint {
                RuleMark(x: .value("Seçili", selected.date))
                    .foregroundStyle(Theme.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selected.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(Theme.secondaryText)
                            
                            Text(String(format: "%.4f", selected.averageRate))
                                .font(.caption)
                                .bold()
                        }
                        .padding(8)
                        .background(Theme.cardBackground)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedPeriod == .week ? 1 : 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.2f", doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                guard let date = proxy.value(atX: x, as: Date.self) else { return }
                                
                                if let point = historicalData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                    selectedPoint = point
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
    }
    
    private var detailsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tarih")
                    .frame(width: 100, alignment: .leading)
                Text("Alış")
                    .frame(maxWidth: .infinity)
                Text("Satış")
                    .frame(maxWidth: .infinity)
                Text("Ort.")
                    .frame(maxWidth: .infinity)
            }
            .font(.caption)
            .foregroundColor(Theme.secondaryText)
            .padding(.vertical, 8)
            .background(Theme.cardBackground)
            
            Divider()
            
            ForEach(historicalData.prefix(7)) { data in
                HStack {
                    Text(data.date.formatted(date: .abbreviated, time: .omitted))
                        .frame(width: 100, alignment: .leading)
                    Text(String(format: "%.4f", data.buyRate))
                        .frame(maxWidth: .infinity)
                    Text(String(format: "%.4f", data.sellRate))
                        .frame(maxWidth: .infinity)
                    Text(String(format: "%.4f", data.averageRate))
                        .frame(maxWidth: .infinity)
                }
                .font(.caption)
                .padding(.vertical, 8)
                
                if data.id != historicalData.prefix(7).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(radius: Theme.shadowRadius)
    }
}

#if DEBUG
struct CurrencyChartView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyChartView(
            currency: Currency(
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
            ),
            historicalData: [],
            viewModel: CurrencyViewModel()
        )
    }
}
#endif 
