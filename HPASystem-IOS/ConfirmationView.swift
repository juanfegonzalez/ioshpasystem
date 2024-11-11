import SwiftUI

struct ConfirmationView: View {
    @Environment(\.dismiss) var dismiss // Para volver a la vista anterior
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo translúcido
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Texto en formato hero
                    Text("Configuración enviada")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                    
                    // Icono de pulgar arriba con sombra y color verde
                    Image(systemName: "hand.thumbsup.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    
                    // Botón de volver con estilo redondeado
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Volver")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 270)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(50)
                            .shadow(radius: 5)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                .padding(.horizontal, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

// Vista previa
struct ConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationView()
            .preferredColorScheme(.dark)
    }
}
