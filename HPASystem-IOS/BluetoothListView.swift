import SwiftUI

struct BluetoothListView: View {
    @EnvironmentObject var viewModel: BluetoothViewModel
    @State private var isLoading = true
    @State private var isConnected = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if isLoading {
                    SkeletonBluetoothListView() // Mostrar el esqueleto mientras carga
                } else if viewModel.peripherals.isEmpty {
                    Text("No se encontraron dispositivos Bluetooth")
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.peripherals.indices, id: \.self) { index in
                            let peripheralInfo = viewModel.peripherals[index]
                            PeripheralRow(peripheralInfo: peripheralInfo, action: {
                                withAnimation {
                                    // Intenta conectar al periférico seleccionado
                                    viewModel.connectToPeripheral(peripheralInfo)
                                    isConnected = peripheralInfo.isConnected // Cambia el estado de conexión
                                }
                            })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Lista de dispositivos:")
            .accentColor(.red)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
            // NavigationDestination para navegar a DashboardView
            .navigationDestination(isPresented: $isConnected) {
                SelectorView()
            }
        }
        //.navigationBarBackButtonHidden(true) // Oculta el botón de retroceso
        .onChange(of: viewModel.peripherals) {
            // Verifica si algún periférico está conectado y cambia el estado de isConnected
            if viewModel.peripherals.contains(where: { $0.isConnected }) {
                isConnected = true
            } else {
                isConnected = false
            }
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
                Text(peripheralInfo.isConnected ? "Desconectar" : "Conectar")
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

struct BluetoothListView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothListView()
            .previewDisplayName("Vista con dispositivos")
            .preferredColorScheme(.dark)
    }
}
