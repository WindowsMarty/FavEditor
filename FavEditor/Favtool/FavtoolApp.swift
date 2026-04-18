//
//  FavtoolApp.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 15/11/22.
//

import SwiftUI



@main
struct FavEditorApp: App {
    @StateObject private var sites = Sites()
    
    var body: some Scene {
        WindowGroup("FavEditor") {
            ContentView()
                .environmentObject(sites)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            FavEditorCommands()
        }
    }
}






