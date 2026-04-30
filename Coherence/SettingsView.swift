import SwiftUI

struct SettingsView: View {
    @Binding var pattern: Pattern
    @Binding var selectedId: String?
    @Binding var customPattern: Pattern
    @Binding var haptics: Bool
    @Binding var audio: Bool
    @Binding var durationMin: Int
    var onClose: () -> Void

    private let bg = Color(red: 0x0a/255, green: 0x0a/255, blue: 0x0a/255)
    private let card = Color(red: 0x16/255, green: 0x16/255, blue: 0x16/255)
    private let border = Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255)
    private let activeBorder = Color(red: 0x5b/255, green: 0x9f/255, blue: 0xd6/255)
    private let activeBg = Color(red: 0x10/255, green: 0x28/255, blue: 0x3f/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionLabel("Presets")
                        presetGrid
                        sectionLabel("Custom pattern")
                        customCard
                        sectionLabel("Session length")
                        durationCard
                        sectionLabel("Feedback")
                        feedbackCard
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onClose) {
                Text("Done")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(red: 0x5b/255, green: 0x9f/255, blue: 0xd6/255))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(size: 12, weight: .medium))
            .tracking(1.2)
            .foregroundStyle(Color(red: 0x7a/255, green: 0x7a/255, blue: 0x7a/255))
            .padding(.top, 24)
            .padding(.bottom, 10)
    }

    private var presetGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Presets.all) { p in
                presetCard(name: p.name, benefit: p.benefit, count: p.count, active: p.id == selectedId) {
                    pattern = p.pattern
                    selectedId = p.id
                }
            }
            presetCard(name: "Custom", benefit: "Your pattern", count: patternCount(customPattern), active: selectedId == CUSTOM_ID) {
                pattern = customPattern
                selectedId = CUSTOM_ID
            }
        }
    }

    private func presetCard(name: String, benefit: String, count: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(active
                                         ? Color(red: 0xcf/255, green: 0xe9/255, blue: 0xff/255)
                                         : Color(red: 0xe6/255, green: 0xe6/255, blue: 0xe6/255))
                    Spacer()
                    Text(count)
                        .font(.system(size: 13, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 0x9a/255, green: 0x9a/255, blue: 0x9a/255))
                }
                Text(benefit)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0x7a/255, green: 0x7a/255, blue: 0x7a/255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(active ? activeBg : card)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(active ? activeBorder : border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var customCard: some View {
        VStack(spacing: 0) {
            stepperRow(label: "Inhale", value: $customPattern.inhale, min: 2, max: 20, selectsCustom: true)
            divider
            stepperRow(label: "Hold (full)", value: $customPattern.holdIn, min: 0, max: 20, selectsCustom: true)
            divider
            stepperRow(label: "Exhale", value: $customPattern.exhale, min: 2, max: 20, selectsCustom: true)
            divider
            stepperRow(label: "Hold (empty)", value: $customPattern.holdOut, min: 0, max: 20, selectsCustom: true)
        }
        .padding(.horizontal, 16)
        .background(card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var durationCard: some View {
        VStack(spacing: 0) {
            stepperRow(label: "Duration", value: $durationMin, min: 1, max: 60, unit: " min")
        }
        .padding(.horizontal, 16)
        .background(card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var feedbackCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Haptics")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0xe6/255, green: 0xe6/255, blue: 0xe6/255))
                Spacer()
                Toggle("", isOn: $haptics).labelsHidden()
            }
            .padding(.vertical, 12)
            divider
            HStack {
                Text("Sound cues")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0xe6/255, green: 0xe6/255, blue: 0xe6/255))
                Spacer()
                Toggle("", isOn: $audio).labelsHidden()
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .background(card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func stepperRow(label: String, value: Binding<Int>, min: Int, max: Int, unit: String = "s", selectsCustom: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 0xe6/255, green: 0xe6/255, blue: 0xe6/255))
            Spacer()
            HStack(spacing: 14) {
                stepBtn("−") {
                    if value.wrappedValue > min {
                        value.wrappedValue -= 1
                        if selectsCustom { applyCustomSelection() }
                    }
                }
                Text("\(value.wrappedValue)\(unit)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(minWidth: 60)
                stepBtn("+") {
                    if value.wrappedValue < max {
                        value.wrappedValue += 1
                        if selectsCustom { applyCustomSelection() }
                    }
                }
            }
        }
        .padding(.vertical, 14)
    }

    private func applyCustomSelection() {
        pattern = customPattern
        selectedId = CUSTOM_ID
    }

    private func stepBtn(_ glyph: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(red: 0x26/255, green: 0x26/255, blue: 0x26/255))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(border)
            .frame(height: 1)
    }
}
