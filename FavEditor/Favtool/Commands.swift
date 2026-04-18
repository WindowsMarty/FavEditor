//
//  Commands.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 22/11/22.
//

import Foundation
import SwiftUI


struct FavEditorCommands: Commands {
    
    
    var body: some Commands {
        
        CommandGroup(replacing: .saveItem) {
            Button {ImageFolderIsLocked(true)} label: {Text("Lock Image Folder")}
                .keyboardShortcut("l")
            Button {ImageFolderIsLocked(false)} label: {Text("Unlock Image Folder")}
                .keyboardShortcut("u")
        }
        

        
        CommandGroup(replacing: .pasteboard) {
            Button {restartSafari()} label: {Text("Restart Safari")}
                .keyboardShortcut("r")
            
            Button {
                showSavePanel(path: AppConfig.shared.safariURL)
                removeItems(path: AppConfig.shared.readingListURL)
            } label: {
                Text("Enable Bookmarks Support")
            }.keyboardShortcut(KeyEquivalent("b"), modifiers: [.command, .option])
            
            Button {
                ImageFolderIsLocked(false)
                removeItems(path: AppConfig.shared.touchIconsCacheURL)
                restartSafari()
            } label: {
                Text("Reset Default Icons")
            }.keyboardShortcut(KeyEquivalent("D"), modifiers: [.command, .option])
            
        }
        
        CommandGroup(replacing: .undoRedo) {
            Button {
                AppConfig.shared.safariVersion = .technologyPreview
                showSavePanel(path: AppConfig.shared.touchIconsCacheURL)
            } label: {
                Text("Technology preview support")
            }.keyboardShortcut(KeyEquivalent("D"), modifiers: [.command, .option])
        }
        CommandGroup(replacing: .windowArrangement) {
            EmptyView()
        }
        CommandGroup(replacing: .windowList) {
            EmptyView()
        }
        CommandGroup(replacing: .systemServices) {
            EmptyView()
        }
        CommandGroup(replacing: .toolbar) {
            EmptyView()
        }
    }
}
