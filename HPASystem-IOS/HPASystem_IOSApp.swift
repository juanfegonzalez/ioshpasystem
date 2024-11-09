//
//  HPASystem_IOSApp.swift
//  HPASystem-IOS
//
//  Created by Sergio Garcia martinez on 9/11/24.
//

import SwiftUI

@main
struct HPASystem_IOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
