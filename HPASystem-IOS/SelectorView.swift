//
//  SelectorView.swift
//  HPASystem-IOS
//
//  Created by Sergio Garcia martinez on 11/11/24.
//

import SwiftUI

struct SelectorView: View {
    @EnvironmentObject var viewModel: BluetoothViewModel
    @State private var appearFromBottom = false
    @State private var showAlert = false
    @State private var isConfirm = false


    // Slider bindings
    private var semiModeBinding: Binding<Double> {
        Binding(
            get: { viewModel.semiMode },
            set: { viewModel.semiMode = $0 }
        )
    }
    private var autoModeBinding: Binding<Double> {
        Binding(
            get: { viewModel.autoMode },
            set: { viewModel.autoMode = $0 }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Imagen de fondo ajustada
                Image("background_image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                VStack {
                    // Título
                    Text("Selector")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Menú inferior
                    VStack(spacing: 40) {
                        sliderSection(title: "Semi Mode", value: semiModeBinding)
                        sliderSection(title: "Auto Mode", value: autoModeBinding)
                        
                        // Botón de acción
                        Button(action: saveAction) {
                            Text("Guardar")
                                .fontWeight(.medium)
                                .frame(maxWidth: 270)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(50)
                                .foregroundColor(.white)
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Confirmar Envío"),
                                message: Text("¿Deseas enviar los nuevos datos?"),
                                primaryButton: .default(Text("Enviar")) {
                                    sendData()
                                },
                                secondaryButton: .cancel(Text("Cancelar"))
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: 400, maxHeight: 380)
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.gray.opacity(0.7))
                            .clipShape(RoundedCornersShape(corners: [.topLeft, .topRight], radius: 25))
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 10)
                    .offset(y: appearFromBottom ? 0 : geometry.size.height)
                    .animation(.easeOut(duration: 0.8), value: appearFromBottom)
                    .onAppear {
                        appearFromBottom = true
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Botón de configuración flotante
                VStack {
                    HStack {
                        Spacer()
                        Button(action: openSettings) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(Color.gray.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .accentColor(.white)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isConfirm) {
                ConfirmationView()
            }
        }
    }
    
    // Sección de slider con título y visualización de valor
    private func sliderSection(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display de valor
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                Text("\(String(format: "%.0f", value.wrappedValue * 30)) balas")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // Slider con iconos en ambos extremos
            HStack {
                Image("Sujeto_1") // Imagen para el extremo izquierdo
                    .resizable()
                    .frame(width: 10, height: 20)
                
                Slider(value: value, in: 0...1)
                    .accentColor(.black)
                    .frame(maxWidth: 270)
                
                Image("Sujeto") // Imagen para el extremo derecho
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    // Acción del botón de configuración
    private func openSettings() {
        print("Configuración abierta")
    }
    
    // Acción del botón de guardar
    private func saveAction() {
        showAlert = true
    }
    
    private func sendData() {
        print("Semi Mode: \(viewModel.semiMode), Auto Mode: \(viewModel.autoMode)")
        viewModel.sendHelloToPeripheral(semioModeValue: viewModel.semiMode, autoModeValue: viewModel.autoMode)
        isConfirm = true
    }
}

// Vista personalizada para redondear solo las esquinas específicas
struct RoundedCornersShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Vista previa
struct SelectorView_Previews: PreviewProvider {
    static var previews: some View {
        SelectorView()
            .preferredColorScheme(.dark)
    }
}
