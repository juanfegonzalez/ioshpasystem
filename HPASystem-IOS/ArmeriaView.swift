import SwiftUI

// Modelo de datos para Arma
struct Arma: Identifiable {
    var id = UUID()
    var nombre: String
    var balas: Int
}

struct ArmeriaView: View {
    // Datos mockeados para simular persistencia
    @State private var armas: [Arma] = [
        Arma(nombre: "Pistola", balas: 15),
        Arma(nombre: "Rifle", balas: 30),
        Arma(nombre: "Escopeta", balas: 8)
    ]
    
    @State private var isAddingNewArma = false
    @State private var newArmaName = ""
    @State private var newArmaBullets = ""
    @State private var selectedArma: Arma? = nil // Para manejar la navegación

    var body: some View {
        NavigationStack {
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
                        ForEach(armas) { arma in
                            ArmaListItem(arma: arma, onEdit: { editArma(arma) })
                                .padding(.vertical, 5)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedArma = arma // Selecciona el arma y activa la navegación
                                }
                        }
                        .onDelete(perform: deleteArma)
                    }
                    .listStyle(PlainListStyle())
                    
                    Spacer()
                    
                    Button(action: { isAddingNewArma = true }) {
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
                    .sheet(isPresented: $isAddingNewArma) {
                        addNewArmaView
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { selectedArma != nil },
                set: { if !$0 { selectedArma = nil } }
            )) {
                BluetoothListView()
            }
        }
    }
    
    // Vista para agregar un nuevo arma
    private var addNewArmaView: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Agregar nueva arma")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Nombre del arma")
                        .foregroundColor(.white)
                    
                    TextField("Nombre", text: $newArmaName)
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
                    
                    Text("Número de balas")
                        .foregroundColor(.white)
                    
                    TextField("Cantidad", text: $newArmaBullets)
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
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 20)
                
                Button(action: saveNewArma) {
                    Text("Guardar")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // Función para guardar un nuevo arma
    private func saveNewArma() {
        guard let balas = Int(newArmaBullets), !newArmaName.isEmpty else {
            return
        }
        
        let nuevaArma = Arma(nombre: newArmaName, balas: balas)
        armas.append(nuevaArma)
        isAddingNewArma = false
        newArmaName = ""
        newArmaBullets = ""
    }
    
    // Función para editar un arma existente (mock, sin implementación de edición directa)
    private func editArma(_ arma: Arma) {
        print("Editar \(arma.nombre)")
    }
    
    // Función para eliminar un arma de la lista
    private func deleteArma(at offsets: IndexSet) {
        armas.remove(atOffsets: offsets)
    }
}

// Vista de cada item de la lista con la imagen de fondo
struct ArmaListItem: View {
    var arma: Arma
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
                    Text(arma.nombre)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(arma.balas) balas")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Text("Editar")
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
    }
}
