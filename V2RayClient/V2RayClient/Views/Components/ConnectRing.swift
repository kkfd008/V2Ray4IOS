import SwiftUI

/// 连接环组件
struct ConnectRing: View {
    let state: VPNManager.ConnectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                Circle()
                    .strokeBorder(borderColor, lineWidth: 2)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                state == .connected ? Color(hex: "00e5a0").opacity(0.2) : .clear,
                                lineWidth: 8
                            )
                            .blur(radius: 8)
                            .scaleEffect(state == .connected ? 1.0 : 0.9)
                            .animation(
                                state == .connected ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                                value: state
                            )
                    )
                Image(systemName: iconName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(iconColor)
                    .scaleEffect(state == .connected ? 1.08 : 1.0)
            }
            .frame(width: 136, height: 136)
        }
        .animation(.easeInOut(duration: 0.4), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .connected: return Color(hex: "00e5a0").opacity(0.08)
        default: return Color(hex: "131820")
        }
    }

    private var borderColor: Color {
        switch state {
        case .connected:  return Color(hex: "00e5a0")
        case .connecting: return Color(hex: "00e5a0")
        default:          return Color(white: 1).opacity(0.08)
        }
    }

    private var iconName: String {
        switch state {
        case .disconnected:  return "power"
        case .connecting:    return "arrow.triangle.2.circlepath"
        case .connected:     return "bolt.fill"
        case .disconnecting: return "power"
        }
    }

    private var iconColor: Color {
        switch state {
        case .connected: return Color(hex: "00e5a0")
        default: return Color(hex: "7a8494")
        }
    }
}