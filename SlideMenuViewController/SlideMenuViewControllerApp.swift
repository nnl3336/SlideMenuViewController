//
//  SlideMenuViewControllerApp.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

import SwiftUI

@main
struct SlideMenuViewControllerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
