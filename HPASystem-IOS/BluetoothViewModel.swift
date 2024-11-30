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

struct GetDataRequest: Codable {
    var action: String = "GET_DATA"
}

struct SetDataRequest: Codable {
    var action: String = "SET_DATA"
    let repeticion: Double
}

struct DataResponse: Codable {
    let repeticion: Double
}

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Publicaciones para notificar cambios en la interfaz de usuario
    @Published var peripherals: [PeripheralInfo] = []
    @Published var receivedData: String = "" // Datos recibidos en formato legible
    @Published var semiMode: Double = 0.0
    @Published var autoMode: Double = 0.0

    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    private var characteristicUUID: CBUUID?
    private let sliderScaleFactor: Double = 30.0 // Factor para conversiones de slider
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard !peripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }
        
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let peripheralInfo = PeripheralInfo(peripheral: peripheral, isConnected: false, receivedData: nil, serviceUUID: serviceUUIDs.first, characteristicUUID: nil)
        
        DispatchQueue.main.async {
            self.peripherals.append(peripheralInfo)
            print("Periférico encontrado: \(peripheral.name ?? "Sin Nombre")")
        }
    }
    
    // MARK: - Gestión de Conexiones
    
    func connectToPeripheral(_ peripheralInfo: PeripheralInfo) {
        guard connectedPeripheral == nil else {
            print("Ya hay un periférico conectado. Desconéctalo primero.")
            return
        }
        
        centralManager.stopScan()
        connectedPeripheral = peripheralInfo.peripheral
        characteristicUUID = peripheralInfo.characteristicUUID
        centralManager.connect(peripheralInfo.peripheral, options: nil)
        print("Intentando conectar a: \(peripheralInfo.peripheral.name ?? "Desconocido")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado a \(peripheral.name ?? "Dispositivo Desconocido")")
        if let index = peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            peripherals[index].isConnected = true
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func disconnectPeripheral() {
        guard let peripheral = connectedPeripheral else { return }
        
        centralManager.cancelPeripheralConnection(peripheral)
        if let index = peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            peripherals[index].isConnected = false
            peripherals[index].receivedData = nil
        }
        connectedPeripheral = nil
        characteristicUUID = nil
        print("Desconectado del periférico.")
    }
    
    // MARK: - Escaneo
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("Escaneando periféricos Bluetooth...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Detenido el escaneo de periféricos.")
    }
    
    // MARK: - Manejo de Servicios y Características

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error al descubrir servicios: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Servicio encontrado: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error al descubrir características: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Característica encontrada: \(characteristic.uuid)")
            
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Notificaciones habilitadas para la característica: \(characteristic.uuid)")
            }
            
            if characteristic.uuid == characteristicUUID {
                print("Característica específica encontrada: \(characteristic.uuid)")
            }
        }
    }
    
    // MARK: - Manejo de Datos

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al recibir datos: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("Datos inválidos recibidos.")
            return
        }

        do {
            let response = try JSONDecoder().decode(DataResponse.self, from: data)
            DispatchQueue.main.async {
                self.semiMode = response.repeticion
                print("Datos recibidos: semi_mode = \(response.repeticion)")
            }
        } catch {
            print("Error al decodificar datos recibidos: \(error.localizedDescription)")
            // Puedes imprimir el string recibido para depuración
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Datos recibidos no conformes: \(jsonString)")
            }
        }
    }
    
    private func int32ToSliderValue(_ int32Value: Int32) -> Double {
        return Double(int32Value) / sliderScaleFactor
    }
    
    private func sliderValueToString(_ sliderValue: Double) -> String {
        return String(Int32(sliderValue * sliderScaleFactor))
    }
    
    // MARK: - Enviar Datos

    func sendHelloToPeripheral(semioModeValue: Double, autoModeValue: Double) {
        guard let peripheral = connectedPeripheral, let characteristic = getWritableCharacteristic() else {
            print("No hay periférico conectado o característica para escribir no encontrada.")
            return
        }
        
        let message = "x \(sliderValueToString(semioModeValue)), y: \(sliderValueToString(autoModeValue))"
        if let data = message.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("Mensaje enviado al periférico.")
        } else {
            print("Error al convertir el mensaje en datos.")
        }
    }
    
    
    func sendSetData(semiModeValue: Double) {
        guard let peripheral = connectedPeripheral, let characteristic = getWritableCharacteristic() else {
            print("No hay periférico conectado o característica para escribir no encontrada.")
            return
        }

        let request = SetDataRequest(repeticion: semiModeValue)
        do {
            let data = try JSONEncoder().encode(request)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("Mensaje SET_DATA enviado al periférico con semi_mode: \(semiModeValue)")
        } catch {
            print("Error al codificar el mensaje SET_DATA: \(error.localizedDescription)")
        }
    }
    
    func sendGetData() {
        guard let peripheral = connectedPeripheral, let characteristic = getWritableCharacteristic() else {
            print("No hay periférico conectado o característica para escribir no encontrada.")
            return
        }

        let request = GetDataRequest()
        do {
            let data = try JSONEncoder().encode(request)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("Mensaje GET_DATA enviado al periférico.")
        } catch {
            print("Error al codificar el mensaje GET_DATA: \(error.localizedDescription)")
        }
    }
    
    func getWritableCharacteristic() -> CBCharacteristic? {
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
    
    func getWritableCharacteristicUUID(for peripheral: CBPeripheral) -> CBUUID? {
        guard let services = peripheral.services else { return nil }

        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.properties.contains(.write) {
                        return characteristic.uuid
                    }
                }
            }
        }
        return nil
    }
    
    func getReadbleCharacteristicUUID(for peripheral: CBPeripheral) -> CBUUID? {
        guard let services = peripheral.services else { return nil }

        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.properties.contains(.read) {
                        return characteristic.uuid
                    }
                }
            }
        }
        return nil
    }
    
    func reloadPeripherals() {
        // Detener cualquier escaneo en curso
        stopScanning()
        
        // Limpiar la lista de periféricos descubiertos
        DispatchQueue.main.async {
            self.peripherals.removeAll()
        }
        
        // Reiniciar el escaneo después de un breve retraso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startScanning()
            print("Reiniciado el escaneo de periféricos.")
        }
    }
}
