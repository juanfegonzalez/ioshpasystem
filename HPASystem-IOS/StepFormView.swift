import SwiftUI
import CoreData

// ViewModel para gestionar los datos del formulario
// ViewModel para gestionar los datos del formulario
class FormViewModel: ObservableObject {
    // Propiedades relacionadas con el arma
    @Published var weaponName = ""
    @Published var weaponType = ""
    @Published var bulletCount = ""

    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    func saveWeapon() {
        guard let bullets = Int32(bulletCount) else {
            print("El número de balas no es válido")
            return
        }

        let weapon = Weapon(context: viewContext)
        weapon.bullets_magazine = bullets
        weapon.id = UUID()
        weapon.name = weaponName
        weapon.type = weaponType
        weapon.timestamp = Date()

        do {
            try viewContext.save()
            print("Arma guardada exitosamente")
        } catch {
            print("Error al guardar el arma: \(error)")
        }
    }
}


// Vista principal del formulario de pasos
struct StepFormView: View {
    @State private var currentStep = 0
    @State private var activeAlert: ActiveAlert?
    @State private var navigateToArmeriaView = false
    @ObservedObject var viewModel: FormViewModel

    var body: some View {
        NavigationStack {
            VStack {
                stepHeader

                Spacer()

                VStack {
                    if currentStep == 0 {
                        StepOneView(viewModel: viewModel, onNext: nextStep)
                            .transition(.slide)
                    } else if currentStep == 1 {
                        StepTwoView(viewModel: viewModel, onPrevious: previousStep, onNext: nextStep)
                            .transition(.slide)
                    } else if currentStep == 2 {
                        StepThreeView(viewModel: viewModel, onPrevious: previousStep, onFinish: completeForm)
                            .transition(.slide)
                    }
                }
                .padding(.horizontal, 30)
                .animation(.easeInOut(duration: 0.5), value: currentStep)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .validationError(let message):
                    return Alert(
                        title: Text("Error de Validación"),
                        message: Text(message),
                        dismissButton: .default(Text("Entendido"))
                    )
                }
            }
            .navigationDestination(isPresented: $navigateToArmeriaView) {
                ArmeriaView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
    }

    // Enum para gestionar los diferentes tipos de alertas
    private enum ActiveAlert: Identifiable {
        case validationError(message: String)

        var id: String {
            switch self {
            case .validationError(let message):
                return message
            }
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
        switch currentStep {
        case 0:
            if viewModel.weaponName.isEmpty {
                activeAlert = .validationError(message: "Por favor, introduzca el nombre de su arma.")
            } else {
                currentStep += 1
            }
        case 1:
            if viewModel.weaponType.isEmpty {
                activeAlert = .validationError(message: "Por favor, seleccione el tipo de arma.")
            } else {
                currentStep += 1
            }
        default:
            break
        }
    }

    // Retroceder al paso anterior
    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    // Finalizar formulario y navegar a ArmeriaView
    private func completeForm() {
        if viewModel.bulletCount.isEmpty {
            activeAlert = .validationError(message: "Por favor, introduzca el número de balas.")
        } else if Int(viewModel.bulletCount) == nil {
            activeAlert = .validationError(message: "El número de balas debe ser un número.")
        } else {
            // Guardar el arma en Core Data
            viewModel.saveWeapon()
            navigateToArmeriaView = true
        }
    }
}
import SwiftUI

// Paso 1: Nombre del arma
struct StepOneView: View {
    @ObservedObject var viewModel: FormViewModel
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

                TextField("Nombre", text: $viewModel.weaponName)
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

            // Botón de siguiente
            Button(action: {
                onNext()
            }) {
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

import SwiftUI

// Paso 2: Tipo del arma (selector)
struct StepTwoView: View {
    @ObservedObject var viewModel: FormViewModel
    var onPrevious: () -> Void
    var onNext: () -> Void

    let weaponTypes = ["Pistola", "Escopeta", "Rifle", "Francotirador", "Apollo"]

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Seleccione el tipo de arma")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
            Spacer()

            Image(systemName: "wrench.and.screwdriver.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)

            Spacer()

            VStack(spacing: 15) {
                Text("Tipo de Arma")
                    .foregroundColor(.white)
                    .font(.headline)

                Picker(selection: $viewModel.weaponType, label: Text("Tipo de Arma")) {
                    ForEach(weaponTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .background(Color.black)
                .cornerRadius(8)
                .padding()
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

                Button(action: {
                    onNext()
                }) {
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

import SwiftUI

// Paso 3: Número de balas en el cargador
struct StepThreeView: View {
    @ObservedObject var viewModel: FormViewModel
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
                Text("Introduce el número de balas de tu cargador")
                    .foregroundColor(.white)
                    .font(.headline)

                TextField("Balas en el cargador", text: $viewModel.bulletCount)
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
                    .keyboardType(.numberPad)
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

                Button(action: {
                    onFinish()
                }) {
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
// Toggle estilo checkbox




// Vista previa
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        StepFormView(viewModel: FormViewModel())
            .preferredColorScheme(.dark)
    }
}
