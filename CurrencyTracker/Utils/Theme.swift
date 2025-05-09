import SwiftUI

enum Theme {
    // Ana renkler
    static let primary = Color("PrimaryColor") // Koyu mavi
    static let secondary = Color("SecondaryColor") // Turkuaz
    static let accent = Color("AccentColor") // Altın sarısı
    
    // Arka plan renkleri
    static let background = Color("BackgroundColor") // Açık gri arka plan
    static let cardBackground = Color.white
    static let secondaryBackground = Color("SecondaryBackground") // Kart arka planı
    
    // Metin renkleri
    static let text = Color("TextColor") // Ana metin rengi
    static let secondaryText = Color("SecondaryTextColor") // İkincil metin rengi
    
    // Özel renkler
    static let positive = Color("PositiveColor") // Yeşil (artış için)
    static let negative = Color("NegativeColor") // Kırmızı (düşüş için)
    
    // Boyutlar
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
    
    // Köşe yuvarlaklığı
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
    
    // Gölge
    static let shadowRadius: CGFloat = 5
    static let shadowColor = Color.black
    static let shadowOffset = CGSize(width: 0, height: 2)
    
    // Animasyon
    static let defaultAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
} 