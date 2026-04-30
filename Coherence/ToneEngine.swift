import Foundation
import AVFoundation

final class ToneEngine {
    static let shared = ToneEngine()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var configured = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    private func setup() {
        guard !configured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            NSLog("ToneEngine: audio session error: \(error)")
        }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0
        do {
            try engine.start()
            player.play()
            configured = true
        } catch {
            NSLog("ToneEngine: engine start error: \(error)")
        }
    }

    func prepare() {
        setup()
    }

    func play(phase: Phase, duration: Double) {
        guard phase == .inhale || phase == .exhale else { return }
        guard duration > 0.05 else { return }
        setup()

        let low: Double = 261.63   // C4
        let high: Double = 523.25  // C5
        let (f0, f1) = phase == .inhale ? (low, high) : (high, low)

        guard let buffer = makeSweep(f0: f0, f1: f1, duration: duration) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
    }

    func stop() {
        player.stop()
        player.play()
    }

    private func makeSweep(f0: Double, f1: Double, duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return nil }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return nil }

        let total = Int(frameCount)
        let twoPi = 2.0 * Double.pi
        let logRatio = log(f1 / f0)
        let coeff = f0 * duration / logRatio

        let attack = max(1, Int(sampleRate * 0.06))
        let release = max(1, Int(sampleRate * 0.18))
        let peak = 0.45

        for i in 0..<total {
            let t = Double(i) / sampleRate
            let phaseValue = twoPi * coeff * (exp(logRatio * t / duration) - 1.0)

            var env = peak
            if i < attack {
                let x = Double(i) / Double(attack)
                env *= x * x * (3 - 2 * x)
            } else if i > total - release {
                let x = Double(total - i) / Double(release)
                env *= x * x * (3 - 2 * x)
            }

            channel[i] = Float(sin(phaseValue) * env)
        }
        return buffer
    }
}
