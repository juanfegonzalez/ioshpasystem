import SwiftUI

struct BluetoothListView: View {
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel
    @Environment(\.managedObjectContext) private var viewContext

    @State var selectedWeapon: Weapon // Arma seleccionada

    @State private var isLoading = true
    @State private var isConnected = false
    @State private var goSelector = false


    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if isLoading {
                    SkeletonBluetoothListView() // Mostrar el esqueleto mientras carga
                } else if bluetoothViewModel.peripherals.isEmpty {
                    VStack {
                        Text("No se encontraron dispositivos Bluetooth")
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button(action: bluetoothViewModel.reloadPeripherals) {
                            Text("Recargar")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 4)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    List {
                        ForEach(bluetoothViewModel.peripherals.indices, id: \.self) { index in
                            let peripheralInfo = bluetoothViewModel.peripherals[index]
                            PeripheralRow(peripheralInfo: peripheralInfo, action: {
                                withAnimation {
                                    bluetoothViewModel.connectToPeripheral(peripheralInfo)
                                    isConnected = peripheralInfo.isConnected
                                    if peripheralInfo.isConnected {
                                        saveBluetoothData(for: peripheralInfo)
                                        goSelector.toggle()
                                    }
                                }
                            })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Lista de dispositivos")
            .navigationDestination(isPresented: $goSelector) {
                SelectorView(selectedWeapon: selectedWeapon )
            }
            .accentColor(.red)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
        }
        .onChange(of: bluetoothViewModel.peripherals) { _ in
            isConnected = bluetoothViewModel.peripherals.contains { $0.isConnected }
        }
    }

    // Guardar datos del periférico conectado en el arma seleccionada
    private func saveBluetoothData(for peripheralInfo: PeripheralInfo) {
        // Actualizar datos del arma seleccionada
        selectedWeapon.bluetoothName = peripheralInfo.peripheral.name
        print(peripheralInfo.peripheral.name)
        selectedWeapon.serviceUUID = peripheralInfo.serviceUUID?.uuidString
        print(peripheralInfo.serviceUUID?.uuidString)

        // Acceso directo al método desde viewModel
        if let writableUUID = bluetoothViewModel.getWritableCharacteristicUUID(for: peripheralInfo.peripheral) {
            selectedWeapon.characteristicWriteUUID = writableUUID.uuidString
            print(writableUUID.uuidString)
        }
        
        if let readableUUID = bluetoothViewModel.getReadbleCharacteristicUUID(for: peripheralInfo.peripheral) {
            selectedWeapon.characteristicReadUUID = readableUUID.uuidString
            print(readableUUID.uuidString)
        }

        do {
            try viewContext.save()
            print("Datos del Bluetooth guardados en el arma seleccionada.")
        } catch {
            print("Error al guardar los datos en Core Data: \(error.localizedDescription)")
        }
    }
}

struct PeripheralRow: View {
    let peripheralInfo: PeripheralInfo
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "wifi")
                .font(.title)
                .foregroundColor(.red)

            VStack(alignment: .leading) {
                Text(peripheralInfo.peripheral.name ?? "Dispositivo Desconocido")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)
                Text("Estado: \(peripheralInfo.isConnected ? "Conectado" : "Desconectado")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: action) {
                Text(peripheralInfo.isConnected ? "Conectado 👍" : "Conectar")
                    .fontWeight(.bold)
                    .padding(10)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 4)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
}
