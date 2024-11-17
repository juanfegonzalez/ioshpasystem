//
//  WelcomeView.swift
//  HPASystem-IOS
//
//  Created by Sergio Garcia Martinez on 17/11/24.
//

import SwiftUI
import CoreData

class WelcomeFormViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var acceptTerms: Bool = false
    @Published var acceptAdvertising: Bool = false
    @Published var userExists: Bool = false  // Nueva propiedad

    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        // Intentar cargar el usuario existente
        fetchExistingUser()
    }

    private func fetchExistingUser() {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            if let user = try viewContext.fetch(fetchRequest).first {
                // Si existe un usuario, cargar sus datos
                self.email = user.email ?? ""
                self.name = user.name ?? ""
                self.userExists = true  // Indicar que el usuario existe
            } else {
                self.userExists = false
            }
        } catch {
            print("Error al obtener el usuario existente: \(error)")
            self.userExists = false
        }
    }

    func saveUser() {
        let user = User(context: viewContext)
        user.email = self.email
        user.name = self.name
        user.id = UUID()
        do {
            try viewContext.save()
            self.userExists = true  // Actualizar la propiedad después de guardar
        } catch {
            print("Error al guardar el usuario: \(error)")
        }
    }
}

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeFormViewModel
    @State private var activeAlert: ActiveAlert?
    @State private var navigateToStepFormView = false
    @State private var navigateToArmeriaView = false  // Nueva propiedad de estado

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Corregido: Eliminamos el signo de dólar en viewModel.name
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
                    Text("Introduzca su nombre")
                        .foregroundColor(.white)
                        .font(.headline)

                    TextField("Nombre", text: $viewModel.name)
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
                        .autocapitalization(.words)

                    Text("Introduzca su email")
                        .foregroundColor(.white)
                        .font(.headline)

                    TextField("email@example.com", text: $viewModel.email)
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
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                // Checkboxes
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $viewModel.acceptTerms) {
                        Text("Acepto los términos de uso")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    Toggle(isOn: $viewModel.acceptAdvertising) {
                        Text("Acepto el envío de publicidad")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
                .padding(.horizontal, 20)

                // Botón de siguiente
                Button(action: {
                    validateAndNavigate()
                }) {
                    Text("Siguiente")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 270)
                        .background(viewModel.acceptTerms ? Color.red.opacity(0.8) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 40)
                .disabled(!viewModel.acceptTerms)
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
            }
            .background(Color.black.opacity(0.6).ignoresSafeArea())
            .onAppear {
                if viewModel.userExists {
                    navigateToArmeriaView = true
                }
            }
            .onReceive(viewModel.$userExists) { userExists in
                if userExists {
                    navigateToArmeriaView = true
                }
            }
            .navigationDestination(isPresented: $navigateToArmeriaView) {
                ArmeriaView()
            }
            .navigationDestination(isPresented: $navigateToStepFormView) {
                StepFormView(viewModel: FormViewModel())
            }
        }
    }

    // Enum para alertas
    private enum ActiveAlert: Identifiable {
        case validationError(message: String)

        var id: String {
            switch self {
            case .validationError(let message):
                return message
            }
        }
    }

    private func validateAndNavigate() {
        if viewModel.name.isEmpty {
            activeAlert = .validationError(message: "Por favor, introduzca su nombre.")
        } else if viewModel.email.isEmpty {
            activeAlert = .validationError(message: "Por favor, introduzca su email.")
        } else if !isValidEmail(viewModel.email) {
            activeAlert = .validationError(message: "Por favor, introduzca un email válido.")
        } else if !viewModel.acceptTerms {
            activeAlert = .validationError(message: "Debe aceptar los términos de uso para continuar.")
        } else {
            // Guardar el usuario en Core Data
            viewModel.saveUser()
            navigateToArmeriaView = true  // Navegar a ArmeriaView después de guardar
        }
    }

    // Validación básica de email
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9.'_%+-]+)@(?:[a-zA-Z0-9.-]+)\\.[a-zA-Z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

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

#Preview {
    WelcomeView(viewModel: WelcomeFormViewModel())
        .preferredColorScheme(.dark)
}
