import SwiftUI

/// Toast 提示
struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool

    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "e4e8ee"))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "1a212b"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(white: 1).opacity(0.08), lineWidth: 1))
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? -8 : 0)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    isPresented = false
                }
            }
    }
}