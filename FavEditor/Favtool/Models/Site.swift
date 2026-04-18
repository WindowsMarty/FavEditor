//
//  Site.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 15/11/22.
//

import Foundation
import CryptoKit
import SwiftUI
import PublicSuffix

struct Site: Identifiable, Hashable {
    var id: Int
    var host: String
    var name: String
    var fullURL: String?
    var transparencyResult: Int
    var iconPath: URL
    
    var md5: String {
        host.toMD5()
    }
    
    var domainName: String {
        let components = SuffixList.default.parse(self.host)
        if let sld = components?.sld {
            return sld.capitalized
        } else {
            return self.host.split(separator: ".").first?.lowercased().capitalized ?? self.host
        }
    }
    
    var icon: some View {
        AsyncImage(url: iconPath) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Image(systemName: "globe")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.secondary.opacity(0.3))
        }
    }

    mutating func setTransparency(value: Int) {
        transparencyResult = value
    }
}

var nullSite = Site(id: -1, host: "www.apple.com", name: "Apple", transparencyResult: 1, iconPath: URL(string: "about:blank")!)
