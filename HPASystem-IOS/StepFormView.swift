import SwiftUI

struct StepFormView: View {
    @State private var currentStep = 0
    @State private var formValues = ["", ""]
    @State private var weaponName = ""
    @State private var bulletCount = ""
    @State private var showValidationAlert = false
    @State private var navigateToBluetoothListView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                stepHeader
                
                Spacer()
                
                VStack {
                    if currentStep == 0 {
                        StepOneView(value: $formValues[0]) {
                            nextStep()
                        }
                    } else if currentStep == 1 {
                        StepTwoView(weaponName: $weaponName, bulletCount: $bulletCount, onPrevious: previousStep, onNext: nextStep)
                    } else if currentStep == 2 {
                        StepThreeView(value: $formValues[1], onPrevious: previousStep, onFinish: completeForm)
                    }
                }
                .padding(.horizontal, 30)
                .transition(.slide)
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                
                Spacer()
                
                NavigationLink(
                    destination: ArmeriaView(),
                    isActive: $navigateToBluetoothListView,
                    label: { EmptyView() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
            .alert(isPresented: $showValidationAlert) {
                Alert(
                    title: Text("Completa el Paso"),
                    message: Text("Por favor, completa la información antes de continuar."),
                    dismissButton: .default(Text("Entendido"))
                )
            }
        }
        .navigationDestination(isPresented: $navigateToBluetoothListView) {
            BluetoothListView()
        }
    }
    
    // Encabezado del paso
    private var stepHeader: some View {
        HStack(spacing: 10) {
            ForEach(0...2, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.green : Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(index <= currentStep ? .white : .gray)
                            .padding(4)
                            .background(Circle().fill(Color.gray.opacity(0.7)))
                    )
                    .frame(maxWidth: index == currentStep ? 40 : 25)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.4), value: currentStep)
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    // Validar y avanzar al siguiente paso
    private func nextStep() {
        let isCurrentValueEmpty: Bool
        
        if currentStep == 1 {
            isCurrentValueEmpty = weaponName.isEmpty || bulletCount.isEmpty
        } else {
            isCurrentValueEmpty = formValues[currentStep].isEmpty
        }
        
        if isCurrentValueEmpty {
            showValidationAlert = true
        } else {
            currentStep += 1
        }
    }
    
    // Retroceder al paso anterior
    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    // Finalizar formulario y navegar a BluetoothListView
    private func completeForm() {
        if formValues[1].isEmpty {
            showValidationAlert = true
        } else {
            navigateToBluetoothListView = true
        }
    }
}

// Paso 1
struct StepOneView: View {
    @Binding var value: String
    @State private var acceptTerms = false
    @State private var acceptAdvertising = false
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Bienvenido")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            Spacer()

            Image(systemName: "lasso.badge.sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Introduzca su email")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("emailexample.com", text: $value)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    .accentColor(.red)
            }
            
            // Checkboxes
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $acceptTerms) {
                    Text("Acepto los términos de uso")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Toggle(isOn: $acceptAdvertising) {
                    Text("Acepto el envío de publicidad")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(CheckboxToggleStyle())
            }
            .padding(.horizontal, 20)
            
            // Botón de siguiente
            Button(action: {
                if acceptTerms && acceptAdvertising {
                    onNext()
                } else {
                    // Muestra alerta si no se han aceptado los términos
                    print("Debes aceptar ambos términos para continuar.")
                }
            }) {
                Text("Siguiente")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 270)
                    .background((acceptTerms && acceptAdvertising) ? Color.red.opacity(0.8) : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(50)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 40)
            .disabled(!acceptTerms || !acceptAdvertising)
        }
    }
}

// Toggle estilo checkbox
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

// Paso 2
struct StepTwoView: View {
    @Binding var weaponName: String
    @Binding var bulletCount: String
    var onPrevious: () -> Void
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Configura tu gatillo")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            Spacer()
            
            Image(systemName: "pencil.and.ruler.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Nombra tu arma")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("Nombre", text: $weaponName)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    .accentColor(.red)
            }
            
            VStack(spacing: 15) {
                Text("Introduce el numero de balas de tu cargador")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("Balas en el cargador", text: $bulletCount)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    .accentColor(.red)
            }
            
            HStack(spacing: 20) {
                Button(action: onPrevious) {
                    Text("Volver")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 5)
                }
                
                Button(action: onNext) {
                    Text("Siguiente")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

// Paso 3
struct StepThreeView: View {
    @Binding var value: String
    var onPrevious: () -> Void
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Detalles del cargador")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            Spacer()

            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)

            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Introduce el numero de balas de tu cargador")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("Balas en el cargador", text: $value)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    .accentColor(.red)
            }
            
            HStack(spacing: 20) {
                Button(action: onPrevious) {
                    Text("Volver")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 5)
                }
                
                Button(action: onFinish) {
                    Text("Finalizar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

// Vista BluetoothListView Placeholder


// Vista previa
struct StepFormView_Previews: PreviewProvider {
    static var previews: some View {
        StepFormView()
            .preferredColorScheme(.dark)
    }
}
