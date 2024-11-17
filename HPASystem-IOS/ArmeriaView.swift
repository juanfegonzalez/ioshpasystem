import SwiftUI
import CoreData

struct ArmeriaView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // FetchRequest para obtener las armas desde Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Weapon.timestamp, ascending: true)],
        animation: .default)
    private var weapons: FetchedResults<Weapon>

    @State private var navigateToStepFormView = false
    @State private var selectedWeapon: Weapon? = nil // Para manejar la navegación

    var body: some View {
        
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()

                VStack {
                    Text("Armería")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 4)

                    Spacer()

                    List {
                        ForEach(weapons) { weapon in
                            WeaponListItem(weapon: weapon, onEdit: { editWeapon(weapon) })
                                .padding(.vertical, 5)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedWeapon = weapon // Selecciona el arma y activa la navegación
                                }
                        }
                        .onDelete(perform: deleteWeapon)
                    }
                    .listStyle(PlainListStyle())

                    Spacer()

                    // Botón "Agregar Arma" modificado para navegar a StepFormView
                    Button(action: { navigateToStepFormView = true }) {
                        Text("Agregar Arma")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 300)
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(50)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            // Navegación a StepFormView
            .navigationDestination(isPresented: $navigateToStepFormView) {
                StepFormView(viewModel: FormViewModel(context: viewContext))
            }
            // Navegación a otra vista si es necesario
            .navigationDestination(isPresented: Binding(
                get: { selectedWeapon != nil },
                set: { if !$0 { selectedWeapon = nil } }
            )) {
                // Aquí podrías navegar a una vista detallada del arma seleccionada
                // WeaponDetailView(weapon: selectedWeapon!)
                BluetoothListView()
            }
        
    }

    // Función para editar un arma existente (puedes implementar la lógica según tus necesidades)
    private func editWeapon(_ weapon: Weapon) {
        // Implementa la funcionalidad de edición aquí
        print("Editar \(weapon.name ?? "Arma sin nombre")")
    }

    // Función para eliminar un arma de la lista
    private func deleteWeapon(at offsets: IndexSet) {
        for index in offsets {
            let weapon = weapons[index]
            viewContext.delete(weapon)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error al eliminar el arma: \(error)")
        }
    }
}

// Vista de cada item de la lista con la imagen de fondo
struct WeaponListItem: View {
    var weapon: Weapon
    var onEdit: () -> Void

    var body: some View {
        ZStack {
            // Imagen de fondo limitada al tamaño del item
            Image("rifle") // Asegúrate de que la imagen esté en tus assets con este nombre
                .resizable()
                .scaledToFill()
                .frame(height: 80)
                .opacity(0.6)
                .cornerRadius(10)
                .clipped()

            // Contenido del item
            HStack(spacing: 15) {
                Image(systemName: "scope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .shadow(color: .black.opacity(0.3), radius: 5)

                VStack(alignment: .leading, spacing: 5) {
                    Text(weapon.name ?? "Sin nombre")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(weapon.bullets_magazine) balas")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onEdit) {
                    Text("Conectar")
                        .font(.caption)
                        .padding(8)
                        .background(Color.blue.opacity(0.3))
                        .foregroundColor(.blue)
                        .cornerRadius(5)
                }
            }
            .padding()
            .background(Color.black.opacity(0.5).cornerRadius(10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(height: 80)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Vista previa
struct ArmeriaView_Previews: PreviewProvider {
    static var previews: some View {
        ArmeriaView()
            .preferredColorScheme(.dark)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
