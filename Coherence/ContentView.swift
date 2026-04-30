import SwiftUI
import UIKit

struct PersistedState: Codable {
    var pattern: Pattern
    var selectedId: String?
    var haptics: Bool
    var audio: Bool
    var durationMin: Int
    var customPattern: Pattern?
}

struct ContentView: View {
    @State private var pattern: Pattern = Presets.all[0].pattern
    @State private var selectedId: String? = Presets.all[0].id
    @State private var customPattern: Pattern = DEFAULT_CUSTOM_PATTERN
    @State private var haptics: Bool = true
    @State private var audio: Bool = false
    @State private var durationMin: Int = 5
    @State private var settingsOpen: Bool = false
    @State private var streakState: StreakState = StreakStore.load()
    @State private var didLoadState = false

    @StateObject private var engine = BreathEngine(pattern: Presets.all[0].pattern)

    private let storeKey = "coherence:state:v1"
    private let bg = Color(red: 0x0a/255, green: 0x0a/255, blue: 0x0a/255)
    private let accent = Color(red: 123/255, green: 168/255, blue: 170/255)
    private let primary = Color(red: 0xe6/255, green: 0xe6/255, blue: 0xe6/255)
    private let muted = Color(red: 0x7a/255, green: 0x7a/255, blue: 0x7a/255)

    var body: some View {
        GeometryReader { geo in
            let orbSize = min(geo.size.width * 0.78, 360)
            ZStack {
                bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: 0)
                    centerStack(orbSize: orbSize)
                    Spacer(minLength: 0)
                    bottom
                }
            }
        }
        .onAppear {
            loadState()
            engine.pattern = pattern
            engine.hapticsEnabled = haptics
            engine.onPhaseEnter = { phase in
                if audio {
                    let dur = Double(pattern.duration(of: phase))
                    ToneEngine.shared.play(phase: phase, duration: dur)
                }
            }
        }
        .onChange(of: pattern) { _, new in
            engine.pattern = new
            saveState()
        }
        .onChange(of: haptics) { _, new in
            engine.hapticsEnabled = new
            saveState()
        }
        .onChange(of: audio) { _, on in
            if on { ToneEngine.shared.prepare() }
            saveState()
        }
        .onChange(of: durationMin) { _, _ in saveState() }
        .onChange(of: selectedId) { _, _ in saveState() }
        .onChange(of: customPattern) { _, _ in saveState() }
        .onChange(of: engine.running) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        .onChange(of: engine.elapsed) { _, e in
            if engine.running, e >= durationMin * 60 { finishSession() }
        }
        .sheet(isPresented: $settingsOpen) {
            SettingsView(
                pattern: $pattern,
                selectedId: $selectedId,
                customPattern: $customPattern,
                haptics: $haptics,
                audio: $audio,
                durationMin: $durationMin,
                onClose: { settingsOpen = false }
            )
            .preferredColorScheme(.dark)
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                settingsOpen = true
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(presetDisplayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(primary)
                    Text(presetSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(streakEmberColor)
                Text("\(StreakStore.visibleStreak(streakState, now: Date()))")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(primary)
            }
            Button {
                settingsOpen = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var streakEmberColor: Color {
        let n = StreakStore.visibleStreak(streakState, now: Date())
        return n > 0
            ? Color(red: 0xff/255, green: 0x8a/255, blue: 0x3d/255)
            : Color(red: 0x4a/255, green: 0x4a/255, blue: 0x4a/255)
    }

    private func centerStack(orbSize: CGFloat) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Text(engine.running ? engine.phase.label.uppercased() : "")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(6)
                    .foregroundStyle(accent.opacity(0.9))
            }
            .frame(height: 28)

            ZStack {
                BreathOrb(progress: engine.progress, size: orbSize)
                Text(engine.running ? "\(Int(ceil(engine.phaseRemaining)))" : "")
                    .font(.system(size: 64, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(Color(red: 0xf5/255, green: 0xef/255, blue: 0xe4/255))
            }
            .frame(width: orbSize, height: orbSize)
        }
    }

    private var bottom: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                stat(label: "Time", value: engine.running ? fmt(remainingSession) : String(format: "%d:00", durationMin))
                Spacer()
                stat(label: "Cycles", value: "\(max(0, engine.cycleCount))")
                Spacer()
            }

            Button {
                if engine.running { finishSession() } else { engine.start() }
            } label: {
                Text(engine.running ? "STOP" : "BEGIN")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(4)
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .contentShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(engine.running ? Color(red: 0x3a/255, green: 0x3a/255, blue: 0x3a/255) : accent, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(primary)
            Text(label.uppercased())
                .font(.system(size: 11))
                .tracking(1.2)
                .foregroundStyle(Color(red: 0x6a/255, green: 0x6a/255, blue: 0x6a/255))
        }
    }

    private var selectedPreset: Preset? {
        Presets.all.first(where: { $0.id == selectedId })
    }

    private var presetDisplayName: String {
        if selectedId == CUSTOM_ID { return "Custom" }
        return selectedPreset?.name ?? "Custom"
    }

    private var presetSubtitle: String {
        if let p = selectedPreset {
            return "\(p.benefit) · \(p.count)"
        }
        return "Your pattern · \(patternCount(pattern))"
    }

    private var remainingSession: Int {
        max(0, durationMin * 60 - engine.elapsed)
    }

    private func fmt(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    private func finishSession() {
        if engine.elapsed >= StreakStore.minSessionSeconds {
            let next = StreakStore.advance(streakState, now: Date())
            streakState = next
            StreakStore.save(next)
        }
        engine.stop()
        ToneEngine.shared.stop()
    }

    private func loadState() {
        guard !didLoadState else { return }
        didLoadState = true
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let s = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        pattern = s.pattern
        selectedId = s.selectedId
        haptics = s.haptics
        audio = s.audio
        durationMin = s.durationMin
        customPattern = s.customPattern ?? DEFAULT_CUSTOM_PATTERN
    }

    private func saveState() {
        let s = PersistedState(pattern: pattern, selectedId: selectedId, haptics: haptics, audio: audio, durationMin: durationMin, customPattern: customPattern)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}
