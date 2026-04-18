//
//  File.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 17/11/22.
//

import Foundation
import SwiftUI
import CryptoKit

enum SafariVersion: String, CaseIterable, Identifiable {
    case standard = "Safari"
    case technologyPreview = "Safari Technology Preview"
    
    var id: String { self.rawValue }
    
    var bundleIdentifier: String {
        switch self {
        case .standard: return "com.apple.Safari"
        case .technologyPreview: return "com.apple.SafariTechnologyPreview"
        }
    }
    
    var appPath: String {
        switch self {
        case .standard: return "/Applications/Safari.app"
        case .technologyPreview: return "/Applications/Safari Technology Preview.app"
        }
    }
}

class AppConfig: ObservableObject {
    static let shared = AppConfig()
    
    @Published var safariVersion: SafariVersion = .standard
    
    var libraryURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }
    
    var safariURL: URL {
        libraryURL.appendingPathComponent("Safari")
    }
    
    var touchIconsCacheURL: URL {
        let base = safariVersion == .technologyPreview ? "SafariTechnologyPreview" : "Safari"
        return libraryURL.appendingPathComponent("\(base)/Touch Icons Cache")
    }
    
    var imagesURL: URL {
        touchIconsCacheURL.appendingPathComponent("Images")
    }
    
    var dbURL: URL {
        touchIconsCacheURL.appendingPathComponent("TouchIconCacheSettings.db")
    }
    
    var readingListURL: URL {
        let base = safariVersion == .technologyPreview ? "SafariTechnologyPreview" : "Safari"
        return libraryURL.appendingPathComponent("\(base)/ReadingListArchives")
    }
}

struct Bookmark: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let host: String?
    let fullURL: String?
    let children: [Bookmark]?
    let systemImage: String?
    
    var md5: String {
        guard let host = host else { return "" }
        return Insecure.MD5
            .hash(data: host.data(using: .utf8)!)
            .map { String(format: "%02hhx", $0) }
            .joined()
            .uppercased()
    }
    
    var isFolder: Bool { children != nil }
}



class BookmarkParser {
    static func fetchBookmarks() -> [Bookmark] {
        let path = AppConfig.shared.safariURL.appendingPathComponent("Bookmarks.plist")
        guard let data = try? Data(contentsOf: path) else {
            return []
        }
        
        do {
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let children = plist["Children"] as? [[String: Any]] {
                return children.compactMap { parseNode($0) }
            }
        } catch {
            print("Error parsing bookmarks: \(error)")
        }
        
        return []
    }
    
    private static func parseNode(_ node: [String: Any]) -> Bookmark? {
        let type = node["WebBookmarkType"] as? String
        let rawTitle = node["Title"] as? String ?? (node["URIDictionary"] as? [String: Any])?["title"] as? String ?? "Untitled"
        
        // 忽略阅读列表
        if rawTitle == "com.apple.ReadingList" { return nil }
        
        var title = rawTitle
        var systemImage: String? = nil
        
        if rawTitle == "BookmarksBar" {
            title = "个人收藏"
            systemImage = "star"
        } else if rawTitle == "BookmarksMenu" {
            title = "标签页个人收藏"
            systemImage = "square.on.square"
        } else if rawTitle == "com.apple.Safari.TabGroupFavorites" || rawTitle.contains("TabGroup") {
            title = "标签页个人收藏"
            systemImage = "square.on.square"
        } else if type == "WebBookmarkTypeList" {
            systemImage = "folder"
        }

        if type == "WebBookmarkTypeList" {
            let children = (node["Children"] as? [[String: Any]])?.compactMap { parseNode($0) } ?? []
            if children.isEmpty && rawTitle != "BookmarksBar" && rawTitle != "BookmarksMenu" { return nil }
            return Bookmark(title: title, host: nil, fullURL: nil, children: children, systemImage: systemImage)
        } else if type == "WebBookmarkTypeLeaf" {
            guard let urlString = node["URLString"] as? String,
                  let url = URL(string: urlString),
                  let host = url.host else {
                return nil
            }
            return Bookmark(title: title, host: host, fullURL: urlString, children: nil, systemImage: "globe")
        }
        
        return nil
    }
}

class Sites: ObservableObject {
    @Published var list: [Site] = []
    @Published var bookmarkTree: [Bookmark] = []
    private var nameMap: [String: String] = [:]
    private var hostMap: [String: String] = [:]
    
    init() {
        refresh()
    }
    
    func refresh() {
        self.bookmarkTree = BookmarkParser.fetchBookmarks()
        self.hostMap = [:] 
        self.nameMap = [:]
        buildMaps(from: self.bookmarkTree)
        
        var combinedSites: [String: Site] = [:]
        
        // 1. Load sites from Database (Safari Cache)
        do {
            let dbRows = try prepareTable()
            for row in dbRows {
                let currentHost = try! row.get(host)
                let transparencyVal = 1 // 全局强制为：透明，大 (玻璃)
                
                let s = Site(
                    id: combinedSites.count,
                    host: currentHost,
                    name: nameMap[currentHost] ?? currentHost,
                    fullURL: hostMap[currentHost],
                    transparencyResult: transparencyVal,
                    iconPath: AppConfig.shared.imagesURL.appendingPathComponent(currentHost.toMD5() + ".png")
                )
                combinedSites[currentHost] = s
            }
        } catch {
            print("Error loading from DB: \(error)")
        }
        
        // 2. Load sites from Bookmarks
        func collectBookmarkHosts(nodes: [Bookmark]) {
            for node in nodes {
                if let hostName = node.host {
                    if combinedSites[hostName] == nil {
                        let s = Site(
                            id: combinedSites.count,
                            host: hostName,
                            name: node.title,
                            fullURL: node.fullURL,
                            transparencyResult: 1, // 全局强制为：透明，大 (玻璃)
                            iconPath: AppConfig.shared.imagesURL.appendingPathComponent(node.md5 + ".png")
                        )
                        combinedSites[hostName] = s
                    } else if combinedSites[hostName]?.fullURL == nil {
                        combinedSites[hostName]?.fullURL = node.fullURL
                    }
                }
                if let children = node.children {
                    collectBookmarkHosts(nodes: children)
                }
            }
        }
        collectBookmarkHosts(nodes: self.bookmarkTree)
        
        self.list = combinedSites.values.sorted { $0.domainName < $1.domainName }
        for i in 0..<self.list.count {
            self.list[i].id = i
        }
    }
    
    private func buildMaps(from nodes: [Bookmark]) {
        for node in nodes {
            if let host = node.host {
                nameMap[host] = node.title
                if let url = node.fullURL {
                    hostMap[host] = url
                }
            }
            if let children = node.children {
                buildMaps(from: children)
            }
        }
    }
    
    func siteForHost(_ hostName: String) -> Site? {
        return list.first { $0.host == hostName }
    }
    
    func findBookmark(id: UUID) -> Bookmark? {
        func search(nodes: [Bookmark]) -> Bookmark? {
            for node in nodes {
                if node.id == id { return node }
                if let children = node.children, let found = search(nodes: children) { return found }
            }
            return nil
        }
        return search(nodes: bookmarkTree)
    }
    
    func siteById(_ id: Int) -> Site {
        return list.first { $0.id == id } ?? nullSite
    }
}

extension String {
    func toMD5() -> String {
        return Insecure.MD5
            .hash(data: self.data(using: .utf8)!)
            .map { String(format: "%02hhx", $0) }
            .joined()
            .uppercased()
    }
}



