import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private var cache: [String: CacheItem] = [:]
    private let expirationTime: TimeInterval = 3600 // 1 saat
    
    struct CacheItem {
        let data: [HistoricalRate]
        let timestamp: Date
    }
    
    func saveToCache(key: String, data: [HistoricalRate]) {
        cache[key] = CacheItem(data: data, timestamp: Date())
    }
    
    func getFromCache(key: String) -> [HistoricalRate]? {
        guard let cacheItem = cache[key] else { return nil }
        
        let now = Date()
        if now.timeIntervalSince(cacheItem.timestamp) > expirationTime {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cacheItem.data
    }
    
    func clearCache() {
        cache.removeAll()
    }
} 