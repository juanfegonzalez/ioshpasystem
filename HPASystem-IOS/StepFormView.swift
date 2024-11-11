import SwiftUI

struct StepFormView: View {
    @State private var currentStep = 0
    @State private var formValues = ["", "", ""]
    @State private var showValidationAlert = false
    
    var body: some View {
        VStack {
            stepHeader
            
            Spacer()
            
            VStack {
                if currentStep == 0 {
                    StepOneView(value: $formValues[0]) {
                        nextStep()
                    }
                } else if currentStep == 1 {
                    StepTwoView(value: $formValues[1], onPrevious: previousStep, onNext: nextStep)
                } else if currentStep == 2 {
                    StepThreeView(value: $formValues[2], onPrevious: previousStep, onFinish: completeForm)
                }
            }
            .padding(.horizontal, 30)
            .transition(.slide)
            .animation(.easeInOut(duration: 0.5), value: currentStep)
            
            Spacer()
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
    
    // Encabezado del paso
    private var stepHeader: some View {
        HStack(spacing: 10) {
            ForEach(0..<formValues.count, id: \.self) { index in
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
        if formValues[currentStep].isEmpty {
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
    
    // Finalizar formulario
    private func completeForm() {
        print("Formulario completado con valores: \(formValues)")
    }
}

// Paso 1
struct StepOneView: View {
    @Binding var value: String
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Configuración Inicial")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            
            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Introduce tu nombre")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("Nombre", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .accentColor(.red)
            }
            
            Button(action: onNext) {
                Text("Siguiente")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 270)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(50)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 40)
        }
    }
}

// Paso 2
struct StepTwoView: View {
    @Binding var value: String
    var onPrevious: () -> Void
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Paso 2: Detalles de Contacto")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Introduce tu correo electrónico")
                    .foregroundColor(.white)
                    .font(.headline)
                
                TextField("Correo electrónico", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
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
           
            
            VStack(spacing: 15) {
                BluetoothListView()
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

// Vista previa
struct StepFormView_Previews: PreviewProvider {
    static var previews: some View {
        StepFormView()
            .preferredColorScheme(.dark)
    }
}
