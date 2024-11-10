import SwiftUI

struct SkeletonBluetoothListView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(0..<7, id: \.self) { _ in
                HStack {
                    // Espacio reservado para el icono de Bluetooth
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .opacity(isAnimating ? 0.5 : 1.0)
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)

                    VStack(alignment: .leading, spacing: 8) {
                        // Espacio reservado para el nombre del dispositivo
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 29)
                            .frame(width: 150)
                            .opacity(isAnimating ? 0.5 : 1.0)
                            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)

                        // Espacio reservado para el estado de conexión
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 19)
                            .opacity(isAnimating ? 0.5 : 1.0)
                            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    Spacer()

                    // Botón de conexión (esqueleto)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 40)
                        .padding()
                        .opacity(isAnimating ? 0.5 : 1.0)
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding(.top, 10)
            }
        }
        .padding(.top, 60)
        .redacted(reason: .placeholder)
        .navigationTitle("Lista de dispositivos:")
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SkeletonBluetoothListView()
}
