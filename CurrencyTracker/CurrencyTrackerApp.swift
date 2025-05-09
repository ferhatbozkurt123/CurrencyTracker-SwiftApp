//
//  CurrencyTrackerApp.swift
//  CurrencyTracker
//
//  Created by Ferhat Bozkurt on 20.01.2025.
//

import SwiftUI

@main
struct CurrencyTrackerApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
