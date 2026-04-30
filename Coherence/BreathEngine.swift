import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class BreathEngine: ObservableObject {
    @Published var running = false
    @Published var phase: Phase = .inhale
    @Published var phaseRemaining: Double = 0
    @Published var cycleCount: Int = 0
    @Published var elapsed: Int = 0
    @Published var progress: Double = 0 // 0 = empty, 1 = full

    var pattern: Pattern {
        didSet {
            if running, oldValue != pattern { restart() }
        }
    }
    var hapticsEnabled: Bool = true
    var onPhaseEnter: ((Phase) -> Void)?

    private var phaseTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var phaseStart: Date = .init()
    private var sessionStart: Date = .init()
    private var animatingProgress = false

    init(pattern: Pattern) {
        self.pattern = pattern
    }

    func start() {
        guard !running else { return }
        running = true
        cycleCount = -1
        elapsed = 0
        sessionStart = Date()
        progress = 0
        startTicker()
        runPhase(.inhale)
    }

    func stop() {
        running = false
        phaseTask?.cancel()
        tickTask?.cancel()
        phaseTask = nil
        tickTask = nil
        withAnimation(.easeOut(duration: 0.6)) {
            progress = 0
        }
    }

    private func restart() {
        phaseTask?.cancel()
        tickTask?.cancel()
        sessionStart = Date()
        elapsed = 0
        cycleCount = -1
        progress = 0
        startTicker()
        runPhase(.inhale)
    }

    private func startTicker() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                guard let self else { return }
                await MainActor.run {
                    self.elapsed = Int(Date().timeIntervalSince(self.sessionStart))
                    let dur = Double(self.pattern.duration(of: self.phase))
                    let elapsedPhase = Date().timeIntervalSince(self.phaseStart)
                    self.phaseRemaining = max(0, dur - elapsedPhase)
                }
            }
        }
    }

    private func runPhase(_ next: Phase) {
        phase = next
        phaseStart = Date()
        if next == .inhale { cycleCount += 1 }
        onPhaseEnter?(next)

        if hapticsEnabled {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                switch next {
                case .inhale: return .medium
                case .exhale: return .light
                case .holdIn, .holdOut: return .soft
                }
            }()
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.impactOccurred()
        }

        let dur = Double(pattern.duration(of: next))
        if next == .inhale {
            withAnimation(.easeInOut(duration: dur)) { progress = 1 }
        } else if next == .exhale {
            withAnimation(.easeInOut(duration: dur)) { progress = 0 }
        }

        let seq = pattern.orderedPhases
        let idx = seq.firstIndex(of: next) ?? 0
        let upcoming = seq[(idx + 1) % seq.count]

        phaseTask?.cancel()
        phaseTask = Task { [weak self] in
            let nanos = UInt64(dur * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled, let self else { return }
            await MainActor.run { self.runPhase(upcoming) }
        }
    }
}
