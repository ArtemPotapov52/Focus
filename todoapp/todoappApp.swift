//
//  todoappApp.swift
//  todoapp
//
//  Created by Артем Потапов on 09.05.2026.
//

import SwiftUI
import CoreData

@main
struct todoappApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
