import Foundation
import CoreBluetooth
import Combine

// Estructura para almacenar información de los periféricos
struct PeripheralInfo: Identifiable, Equatable {
    let peripheral: CBPeripheral
    var isConnected: Bool
    var receivedData: (x: Float, y: Float, z: Float)?
    var serviceUUID: CBUUID?
    var characteristicUUID: CBUUID?

    var id: UUID {
        return peripheral.identifier
    }

    // Implementación del protocolo Equatable
    static func == (lhs: PeripheralInfo, rhs: PeripheralInfo) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier &&
               lhs.isConnected == rhs.isConnected &&
               lhs.serviceUUID == rhs.serviceUUID &&
               lhs.characteristicUUID == rhs.characteristicUUID
    }
}

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Publicaciones para notificar cambios en la interfaz de usuario
    @Published var peripherals: [PeripheralInfo] = []
    @Published var receivedData: String = "" // Para mostrar los datos recibidos de manera legible
    @Published var receivedDataAM: Float?
    @Published var receivedDataVC: Float?
    @Published var receivedDataDC: Float?
    
    @Published var serviceUUIDs: [CBUUID] = []
    @Published var characteristicUUIDs: [CBUUID] = []
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var characteristicUUID: CBUUID?
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Escaneando periféricos Bluetooth...")
        case .poweredOff:
            print("Bluetooth está apagado.")
        case .unsupported:
            print("Bluetooth no es soportado en este dispositivo.")
        case .unauthorized:
            print("La aplicación no está autorizada para usar Bluetooth.")
        case .resetting:
            print("Bluetooth se está reiniciando.")
        case .unknown:
            print("Estado desconocido de Bluetooth.")
        @unknown default:
            print("Estado no manejado de Bluetooth.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Evitar duplicados
        if !peripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
            let peripheralInfo = PeripheralInfo(peripheral: peripheral, isConnected: false, receivedData: nil, serviceUUID: serviceUUIDs.first, characteristicUUID: nil)
            if let name = peripheral.name, !name.isEmpty {
                DispatchQueue.main.async {
                    self.peripherals.append(peripheralInfo)
                    print("Periférico encontrado: \(name)")
                }
            }
        }
    }
    
    // Conectar a un periférico específico
    func connectToPeripheral(_ peripheralInfo: PeripheralInfo) {
        // Verifica si ya hay un periférico conectado
        if connectedPeripheral != nil {
            print("Ya hay un periférico conectado. Desconéctalo primero.")
            return
        }

        centralManager.stopScan()
        connectedPeripheral = peripheralInfo.peripheral
        characteristicUUID = peripheralInfo.characteristicUUID
        centralManager.connect(peripheralInfo.peripheral, options: nil)
        print("Intentando conectar a: \(peripheralInfo.peripheral.name ?? "Desconocido")")
    }
    
    // Confirmación de conexión
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado a \(peripheral.name ?? "Dispositivo Desconocido")")
        if let index = peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            peripherals[index].isConnected = true
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    // Manejar descubrimiento de servicios
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error al descubrir servicios: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Servicio encontrado: \(service.uuid)")
            DispatchQueue.main.async {
                self.serviceUUIDs.append(service.uuid)
            }
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Manejar descubrimiento de características
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error al descubrir características: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Característica encontrada: \(characteristic.uuid)")
            
            // Habilitar notificaciones para características que lo soporten
//            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Notificaciones habilitadas para la característica: \(characteristic.uuid)")
//            }
            
            // Si se requiere una característica específica, almacenarla
            if characteristic.uuid == characteristicUUID {
                DispatchQueue.main.async {
                    self.characteristicUUIDs.append(characteristic.uuid)
                }
            }
        }
    }
    
    // Manejar actualizaciones de valores para características
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al recibir datos: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("No se recibieron datos.")
            return
        }
        
        // Asumimos que los datos contienen 3 valores Float (12 bytes)
        if data.count == MemoryLayout<Float>.size * 3 {
            let values = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> (Float, Float, Float) in
                let floats = pointer.bindMemory(to: Float.self)
                return (floats[0], floats[1], floats[2])
            }
            
            let valor_x = values.0
            let valor_y = values.1
            let valor_z = values.2
            
            DispatchQueue.main.async {
                self.receivedDataAM = valor_x
                self.receivedDataDC = valor_y
                self.receivedDataVC = valor_z
                self.receivedData = String(format: "X: %.2f, Y: %.2f, Z: %.2f", valor_x, valor_y, valor_z)
                
                if let index = self.peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                    self.peripherals[index].receivedData = (x: valor_x, y: valor_y, z: valor_z)
                }
            }
            
            print("Datos recibidos: X: \(valor_x), Y: \(valor_y), Z: \(valor_z)")
        } else {
            print("Datos inválidos recibidos o tamaño incorrecto.")
        }
    }
    
    
    
// Enviar mensaje "hola" al periférico conectado
    func sendHelloToPeripheral() {
        guard let peripheral = connectedPeripheral, let characteristic = getWritableCharacteristic() else {
            print("No hay periférico conectado o característica para escribir no encontrada.")
            return
        }
        
        // Convertir "hola" a datos
        let message = "hola"
        if let data = message.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("Mensaje 'hola' enviado al periférico.")
        } else {
            print("Error al convertir el mensaje en datos.")
        }
    }
    
    // Obtener la característica escribible
    private func getWritableCharacteristic() -> CBCharacteristic? {
        guard let services = connectedPeripheral?.services else { return nil }
        
        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.properties.contains(.write) {
                        return characteristic
                    }
                }
            }
        }
        
        return nil
    }
        
    
    // MARK: - Gestión de Conexiones
    
    func disconnectPeripheral() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            if let index = peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                peripherals[index].isConnected = false
                peripherals[index].receivedData = nil
            }
            connectedPeripheral = nil
            characteristicUUID = nil
            print("Desconectado del periférico.")
        }
    }
}
