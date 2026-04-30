import Foundation

struct StreakState: Codable, Equatable {
    var lastSessionDate: String?
    var streak: Int
    static let empty = StreakState(lastSessionDate: nil, streak: 0)
}

enum StreakStore {
    static let key = "coherence:streak:v1"
    static let minSessionSeconds = 30

    static func dateKey(_ d: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    static func dayDiff(_ a: String, _ b: String) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let f = DateFormatter()
        f.calendar = cal
        f.dateFormat = "yyyy-MM-dd"
        guard let da = f.date(from: a), let db = f.date(from: b) else { return 0 }
        let comps = cal.dateComponents([.day], from: db, to: da)
        return comps.day ?? 0
    }

    static func load() -> StreakState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(StreakState.self, from: data)
        else { return .empty }
        return s
    }

    static func save(_ state: StreakState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func visibleStreak(_ s: StreakState, now: Date) -> Int {
        guard let last = s.lastSessionDate else { return 0 }
        let diff = dayDiff(dateKey(now), last)
        return diff <= 1 ? s.streak : 0
    }

    static func advance(_ s: StreakState, now: Date) -> StreakState {
        let today = dateKey(now)
        if s.lastSessionDate == today { return s }
        if let last = s.lastSessionDate, dayDiff(today, last) == 1 {
            return StreakState(lastSessionDate: today, streak: s.streak + 1)
        }
        return StreakState(lastSessionDate: today, streak: 1)
    }
}
