//
//  Safari.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 16/11/22.
//

import Foundation
import SwiftUI

func restartSafari() {
    let version = AppConfig.shared.safariVersion
    let runningApplications = NSWorkspace.shared.runningApplications
    
    if let safariApp = runningApplications.first(where: { 
        $0.bundleIdentifier == version.bundleIdentifier
    }) {
        safariApp.terminate()
        // Wait a bit for termination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSWorkspace.shared.open(URL(fileURLWithPath: version.appPath))
        }
    } else {
        // Just open it if not running
        NSWorkspace.shared.open(URL(fileURLWithPath: version.appPath))
    }
}

func openURL(_ urlString: String) {
    if let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)
    }
}

func donate() {
    openURL("https://www.paypal.com/paypalme/favtool")
}

func go(target : String) -> Void{
    openURL("https://www.paypal.com/paypalme/favtool")
}

func goTelegram() {
    openURL("https://t.me/shyneon")
}

func goInstagram() {
    openURL("https://www.instagram.com/shy_neon_dev")
}

func goReddit() {
    openURL("https://www.reddit.com/r/favtool/")
}
