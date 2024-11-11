import Foundation
import CoreBluetooth
import Combine

// Estructura para almacenar información de los periféricos
struct PeripheralInfo: Identifiable, Equatable {
    let peripheral: CBPeripheral
    var isConnected: Bool
    var receivedData: (semi_mode: Double, auto_mode: Double)?
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
    @Published var semiMode: Double = 0.0
    @Published var autoMode: Double = 0.0

    
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
    
    
    // Convierte un valor Int32 a Double para el Slider (0.0 - 1.0)
    func int32ToSliderValue(_ int32Value: Int32) -> Double {
        return Double(int32Value) / 30.0
    }

    // Convierte el valor del Slider (Double de 0.0 - 1.0) a Int32
    func sliderValueToString(_ sliderValue: Double) -> String {
        return String(Int32(sliderValue * 30))
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
        
        // Verificar que el tamaño de los datos coincida con 2 valores Int32 (8 bytes)
        guard data.count == MemoryLayout<Int32>.size * 2 else {
            print("Datos inválidos recibidos o tamaño incorrecto.")
            return
        }
        
        // Deserializar los datos en dos valores Int32 (semi_mode y auto_mode)
        let semiMode: Int32 = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Int32.self) }
        let autoMode: Int32 = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        
        // Actualizar los valores en el hilo principal
        DispatchQueue.main.async {
            self.semiMode = self.int32ToSliderValue(semiMode)
            self.autoMode = self.int32ToSliderValue(autoMode)
            self.receivedData = "Semi Mode: \(semiMode), Auto Mode: \(autoMode)"
            
            // Actualizar datos en el periférico específico si es necesario
            if let index = self.peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                self.peripherals[index].receivedData = (semi_mode: self.semiMode, auto_mode: self.autoMode)
            }
        }
        
        print("Datos recibidos: Semi Mode: \(semiMode), Auto Mode: \(autoMode)")
    }
    
    
// Enviar mensaje "hola" al periférico conectado
    func sendHelloToPeripheral(semioModeValue: Double, autoModeValue: Double) {
        guard let peripheral = connectedPeripheral, let characteristic = getWritableCharacteristic() else {
            print("No hay periférico conectado o característica para escribir no encontrada.")
            return
        }
        
        // Convertir "hola" a datos
        let message = "x \(sliderValueToString(semioModeValue)), y: \(sliderValueToString(autoModeValue))"
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
