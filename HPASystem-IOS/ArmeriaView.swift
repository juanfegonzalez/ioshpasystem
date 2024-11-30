import SwiftUI
import CoreBluetooth
import CoreData

struct ArmeriaView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel

    // FetchRequest para obtener las armas desde Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Weapon.timestamp, ascending: true)],
        animation: .default)
    private var weapons: FetchedResults<Weapon>

    @State private var navigateToStepFormView = false
    @State private var selectedWeapon: Weapon? = nil // Para manejar la navegación
    @State private var navigateToBluetoothListView = false
    @State private var navigateToSelectorView = false

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
                    if weapons.isEmpty {
                        Text("No hay armas disponibles.")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                    } else {
                        ForEach(weapons) { weapon in
                            WeaponListItem(weapon: weapon, onEdit: { editWeapon(weapon) })
                                .padding(.vertical, 5)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    handleWeaponSelection(weapon)
                                }
                        }
                        .onDelete(perform: deleteWeapon)
                        
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Botón "Agregar Arma"
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
                .scaleEffect(navigateToStepFormView ? 1.1 : 1.0)
                .animation(.easeInOut, value: navigateToStepFormView)
            }
        }
        .navigationBarHidden(true)
        // Navegación a StepFormView
        .navigationDestination(isPresented: $navigateToStepFormView) {
            StepFormView(viewModel: FormViewModel(context: viewContext))
        }
        // Navegación a BluetoothListView
        .navigationDestination(isPresented: $navigateToBluetoothListView) {
            if let weapon = selectedWeapon {
                BluetoothListView(selectedWeapon: weapon)
                    .environmentObject(bluetoothViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        // Navegación a SelectorView
        .navigationDestination(isPresented: $navigateToSelectorView) {
            if let weapon = selectedWeapon {
                SelectorView(selectedWeapon: weapon)
                    .environmentObject(bluetoothViewModel)
            }
            
        }
    }

    // Función para manejar la selección del arma
    private func handleWeaponSelection(_ weapon: Weapon) {
        selectedWeapon = weapon

        // Verificar si el arma tiene datos de UUIDs guardados
        if let serviceUUID = weapon.characteristicReadUUID,
           let characteristicReadUUID = weapon.characteristicReadUUID,
           let characteristicWriteUUID = weapon.characteristicWriteUUID {
            // Verificar que los UUIDs están disponibles en los servicios de peripheralInfo
            if let conection = bluetoothViewModel.connectedPeripheral{
                if isUUIDsValid(in: conection, serviceUUID: serviceUUID, characteristicReadUUID: characteristicReadUUID, characteristicWriteUUID: characteristicWriteUUID) {
                    navigateToSelectorView = true
                } else {
                    print("Los UUIDs guardados no coinciden con los servicios disponibles.")
                    navigateToBluetoothListView = true
                }
            } else {
                navigateToBluetoothListView = true
            }
        } else {
            print("El arma no tiene datos de UUIDs guardados.")
            navigateToBluetoothListView = true
        }
    }
    
    private func isUUIDsValid(in connectedPeripheral: CBPeripheral, serviceUUID: String, characteristicReadUUID: String, characteristicWriteUUID: String) -> Bool {
        guard let services = connectedPeripheral.services else {
            print("No hay servicios disponibles en el periférico.")
            return false
        }

        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if  characteristic.properties.contains(.read) {
                        var a = characteristic.uuid.uuidString
                        return a == characteristicReadUUID
                    }
                }
            }
        }
        return false
    }


    // Función para editar un arma existente
    private func editWeapon(_ weapon: Weapon) {
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
            Image("rifle")
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
                        .accessibilityLabel("Nombre del arma")

                    Text("\(weapon.bullets_magazine) balas")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()
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
            .environmentObject(BluetoothViewModel())
    }
}
