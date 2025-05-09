import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CurrencyViewModel()
    
    var body: some View {
        TabView {
            CurrencyListView(viewModel: viewModel)
                .tabItem {
                    Label("Kurlar", systemImage: "dollarsign.circle.fill")
                }
            
            ConverterView()
                .tabItem {
                    Label("Çevirici", systemImage: "arrow.left.arrow.right.circle.fill")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favoriler", systemImage: "star.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif 