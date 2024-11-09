//
//  SkeletonBluetoothListView.swift
//  PunchMachine
//
//  Created by Sergio Garcia martinez on 3/10/24.
//
import SwiftUI

struct SkeletonBluetoothListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(0..<7, id: \.self) { _ in
                HStack {
                    // Espacio reservado para el icono de Bluetooth
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 8) {
                        // Espacio reservado para el nombre del dispositivo
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 29)
                            .frame(width: 150)

                        // Espacio reservado para el estado de conexión
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 19) // Ajusta el ancho para el estado
                    }
                    Spacer()

                    // Botón de conexión (esqueleto)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 40)
                        .padding()
                }
                .padding(.top, 10)
            }
        }
        .padding(.top, 60)
        .redacted(reason: .placeholder) // Esta línea hace que el contenido luzca como un placeholder.
        .navigationTitle("Lista de dispositivos:")
    }
}

#Preview {
    SkeletonBluetoothListView()
}
