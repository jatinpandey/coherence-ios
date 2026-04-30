import Foundation

enum Phase: String, Codable {
    case inhale, holdIn, exhale, holdOut

    var label: String {
        switch self {
        case .inhale: return "Inhale"
        case .exhale: return "Exhale"
        case .holdIn, .holdOut: return "Hold"
        }
    }
}

struct Pattern: Codable, Equatable {
    var inhale: Int
    var holdIn: Int
    var exhale: Int
    var holdOut: Int

    func duration(of phase: Phase) -> Int {
        switch phase {
        case .inhale: return inhale
        case .holdIn: return holdIn
        case .exhale: return exhale
        case .holdOut: return holdOut
        }
    }

    var orderedPhases: [Phase] {
        var seq: [Phase] = [.inhale]
        if holdIn > 0 { seq.append(.holdIn) }
        seq.append(.exhale)
        if holdOut > 0 { seq.append(.holdOut) }
        return seq
    }
}

struct Preset: Identifiable, Equatable {
    let id: String
    let name: String
    let benefit: String
    let pattern: Pattern

    var count: String {
        var s = "\(pattern.inhale)-\(pattern.holdIn > 0 ? "\(pattern.holdIn)-" : "")\(pattern.exhale)"
        if pattern.holdOut > 0 { s += "-\(pattern.holdOut)" }
        return s
    }
}

enum Presets {
    static let all: [Preset] = [
        Preset(id: "coherent-6", name: "Coherence",
               benefit: "HRV and resonance",
               pattern: Pattern(inhale: 6, holdIn: 0, exhale: 6, holdOut: 0)),
        Preset(id: "hrv-6", name: "HRV",
               benefit: "Inhale, hold, exhale",
               pattern: Pattern(inhale: 6, holdIn: 6, exhale: 6, holdOut: 0)),
        Preset(id: "box-4", name: "Box",
               benefit: "Focus and composure",
               pattern: Pattern(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)),
        Preset(id: "relax-478", name: "Relax",
               benefit: "Sleep and unwind",
               pattern: Pattern(inhale: 4, holdIn: 7, exhale: 8, holdOut: 0)),
        Preset(id: "energize", name: "Energize",
               benefit: "Wake up alert",
               pattern: Pattern(inhale: 4, holdIn: 2, exhale: 4, holdOut: 0)),
    ]
}

func patternCount(_ p: Pattern) -> String {
    var s = "\(p.inhale)-\(p.holdIn > 0 ? "\(p.holdIn)-" : "")\(p.exhale)"
    if p.holdOut > 0 { s += "-\(p.holdOut)" }
    return s
}

let CUSTOM_ID = "custom"
let DEFAULT_CUSTOM_PATTERN = Pattern(inhale: 5, holdIn: 0, exhale: 5, holdOut: 0)
