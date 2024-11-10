//
//  ConfirmationView.swift
//  HPASystem-IOS
//
//  Created by Sergio Garcia martinez on 11/11/24.
//

import SwiftUI

struct ConfirmationView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Texto en formato hero
                Text("Configuración enviada")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Icono de pulgar arriba
                Image(systemName: "hand.thumbsup.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .ignoresSafeArea()
        }
    }
}

// Vista previa
struct ConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationView()
            .preferredColorScheme(.dark)
    }
}
