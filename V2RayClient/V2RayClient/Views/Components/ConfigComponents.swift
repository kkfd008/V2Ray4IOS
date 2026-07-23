import SwiftUI

// MARK: - Config Section

struct ConfigSection<Content: View>: View {
    let title: String
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
                .textCase(.uppercase)
                .padding(.bottom, 10)
            content()
        }
        .padding(14)
        .background(accent.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.10), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 14)
    }
}

// MARK: - Config Field

struct ConfigField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "4a5462"))
                .textCase(.uppercase)
            TextField(placeholder, text: $text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(hex: "e4e8ee"))
                .padding(11)
                .background(Color(hex: "131820"))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Secure Config Field

struct SecureConfigField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "4a5462"))
                .textCase(.uppercase)
            SecureField(placeholder, text: $text)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(Color(hex: "e4e8ee"))
                .padding(11)
                .background(Color(hex: "131820"))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Config Row

struct ConfigRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 10) { content() }
    }
}

// MARK: - Config Picker

struct ConfigPicker: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "4a5462"))
                .textCase(.uppercase)
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 14, design: .monospaced))
            .tint(Color(hex: "e4e8ee"))
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "131820"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "e4e8ee"))
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "00e5a0"))
        }
        .padding(.vertical, 10)
    }
}