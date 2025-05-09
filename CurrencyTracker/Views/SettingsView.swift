import SwiftUI

struct SettingsView: View {
    @AppStorage("updateInterval") private var updateInterval: Double = 900 // 15 dakika
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationThreshold") private var notificationThreshold: Double = 1.0
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var showingAlert = false
    
    private let updateIntervalOptions: [(String, Double)] = [
        ("5 dakika", 300),
        ("15 dakika", 900),
        ("30 dakika", 1800),
        ("1 saat", 3600)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Güncelleme Ayarları
                Section(header: Text("Güncelleme Ayarları")) {
                    Picker("Güncelleme Sıklığı", selection: $updateInterval) {
                        ForEach(updateIntervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
                
                // Bildirim Ayarları
                Section(header: Text("Bildirim Ayarları")) {
                    Toggle("Bildirimleri Etkinleştir", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    if notificationsEnabled {
                        HStack {
                            Text("Değişim Eşiği (%)")
                            Spacer()
                            TextField("", value: $notificationThreshold, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.decimalPad)
                        }
                        
                        Text("Kur değişimi bu eşiği aştığında bildirim alırsınız")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Görünüm Ayarları
                Section(header: Text("Görünüm Ayarları")) {
                    Toggle("Karanlık Mod", isOn: $darkModeEnabled)
                }
                
                // Uygulama Bilgileri
                Section(header: Text("Uygulama Hakkında")) {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://www.tcmb.gov.tr")!) {
                        HStack {
                            Text("Veri Kaynağı")
                            Spacer()
                            Text("TCMB")
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Gizlilik Politikası")
                    }
                }
                
                // Önbellek Temizleme
                Section {
                    Button(action: {
                        clearCache()
                        showingAlert = true
                    }) {
                        Text("Önbelleği Temizle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .alert("Önbellek Temizlendi", isPresented: $showingAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Tüm önbellek verileri başarıyla temizlendi.")
            }
        }
    }
    
    private func clearCache() {
        Task {
            await CacheManager.shared.clearCache()
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                let authorized = try await NotificationManager.shared.requestAuthorization()
                if !authorized {
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                }
            }
        }
    }
}

// Gizlilik Politikası View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gizlilik Politikası")
                    .font(.title)
                    .bold()
                
                Text("Bu uygulama, TCMB'den alınan döviz kuru verilerini kullanmaktadır. Kullanıcı verileri cihaz üzerinde yerel olarak saklanmaktadır ve üçüncü taraflarla paylaşılmamaktadır.")
                    .font(.body)
                
                Text("Bildirimler")
                    .font(.headline)
                
                Text("Bildirim izni vermeniz durumunda, belirlediğiniz eşik değerlerine göre kur değişimleri hakkında bildirim alırsınız.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Gizlilik Politikası")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif 