import Foundation

// API Response modelleri
struct YapiKrediResponse: Codable {
    let response: ResponseData
}

struct ResponseData: Codable {
    let exchangeRateList: [ExchangeRate]
}

struct ExchangeRate: Codable {
    let averageRate: String
    let sellRate: String
    let minorCurrency: String
    let previousDaySellRate: String
    let majorCurrency: String
    let changeRatioDaily: String
    let previousDayBuyRate: String
    let previousDayAverageRate: String
    let buyRate: String
}

// API Request modeli
struct CurrencyRequest: Codable {
    let validityDate: String
    
    enum CodingKeys: String, CodingKey {
        case validityDate = "ValidityDate"
    }
}

// UI için kullanacağımız model
struct Currency: Identifiable {
    let id = UUID()
    let majorCurrency: String
    let minorCurrency: String
    let name: String
    
    let buyRate: Double
    let sellRate: Double
    let averageRate: Double
    let changeRatio: Double
    
    let previousDayBuyRate: Double
    let previousDaySellRate: Double
    let previousDayAverageRate: Double
    
    // Para birimi adını TL ile birlikte göster
    var displayName: String {
        "\(name) (\(majorCurrency)/TL)"
    }
    
    var pairName: String {
        "\(majorCurrency)/TL"
    }
    
    var formattedChangeRatio: String {
        let prefix = isPositiveChange ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", changeRatio))%"
    }
    
    var isPositiveChange: Bool {
        changeRatio >= 0
    }
}

struct HistoricalRate: Identifiable {
    let id = UUID()
    let date: Date
    let buyRate: Double
    let sellRate: Double
    let averageRate: Double
}

// TCMB XML Response modeli
struct TCMBCurrency: Codable {
    let code: String
    let name: String
    let unit: Int
    let buyRate: Double
    let sellRate: Double
    let effectiveBuyRate: Double
    let effectiveSellRate: Double
    let previousDayBuyRate: Double?
    let previousDaySellRate: Double?
}

// XML parsing için yardımcı sınıf
class TCMBParser: NSObject, XMLParserDelegate {
    private var currencies: [TCMBCurrency] = []
    private var currentElement = ""
    private var currentCode = ""
    private var currentName = ""
    private var currentUnit = ""
    private var currentBuyRate = ""
    private var currentSellRate = ""
    private var currentEffectiveBuyRate = ""
    private var currentEffectiveSellRate = ""
    private var previousDayBuyRate = ""
    private var previousDaySellRate = ""
    
    func parse(data: Data) -> [TCMBCurrency] {
        currencies.removeAll()
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        return currencies
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "Currency" {
            currentCode = attributeDict["CurrencyCode"] ?? ""
            currentUnit = attributeDict["Unit"] ?? "1"
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !data.isEmpty {
            switch currentElement {
            case "Isim":
                currentName = data
            case "ForexBuying":
                currentBuyRate = data
            case "ForexSelling":
                currentSellRate = data
            case "BanknoteBuying":
                currentEffectiveBuyRate = data
            case "BanknoteSelling":
                currentEffectiveSellRate = data
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Currency" {
            let unit = Int(currentUnit) ?? 1
            let buyRate = (Double(currentBuyRate.replacingOccurrences(of: ",", with: ".")) ?? 0) / Double(unit)
            let sellRate = (Double(currentSellRate.replacingOccurrences(of: ",", with: ".")) ?? 0) / Double(unit)
            let effectiveBuyRate = (Double(currentEffectiveBuyRate.replacingOccurrences(of: ",", with: ".")) ?? 0) / Double(unit)
            let effectiveSellRate = (Double(currentEffectiveSellRate.replacingOccurrences(of: ",", with: ".")) ?? 0) / Double(unit)
            
            let currency = TCMBCurrency(
                code: currentCode,
                name: currentName,
                unit: unit,
                buyRate: buyRate,
                sellRate: sellRate,
                effectiveBuyRate: effectiveBuyRate,
                effectiveSellRate: effectiveSellRate,
                previousDayBuyRate: nil, // Şimdilik nil, daha sonra ekleyeceğiz
                previousDaySellRate: nil
            )
            currencies.append(currency)
            
            // Reset current values
            currentBuyRate = ""
            currentSellRate = ""
            currentEffectiveBuyRate = ""
            currentEffectiveSellRate = ""
        }
    }
} 