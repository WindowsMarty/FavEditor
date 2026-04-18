//
//  SideBar.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 17/11/22.
//

import SwiftUI
import AppKit

struct SideBarView: View {
    @EnvironmentObject var sites: Sites
    @State private var showingAlert = false
    @State private var interactionCount = 0
    @State private var selection: UUID?
    @State private var refreshing = false
    @State private var isLocked = false
    @State private var progress = 0.0
    @State private var statusMessage = "请授权访问 Safari 文件夹"
    @State private var isGranted = false
    
    @State private var showingRefreshAlert = false
    @State private var showingLockAlert = false
    @State private var searchText = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                if !sites.bookmarkTree.isEmpty && !refreshing {
                    List(selection: $selection) {
                        ForEach(sites.bookmarkTree) { bookmark in
                            BookmarkRow(bookmark: bookmark, sites: sites)
                        }
                    }
                    .listStyle(.sidebar)
                } else if !refreshing {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.folder.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48)
                            .foregroundColor(Color.secondary.opacity(0.3))
                        
                        Text(statusMessage)
                            .multilineTextAlignment(.center)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        Button {
                            showSavePanel(path: AppConfig.shared.safariURL)
                            statusMessage = ImageFolderIsLocked(false)
                            restartSafari()
                            refreshList()
                            isGranted = true
                        } label: {
                            Text(isGranted ? "重试" : "授权访问")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if refreshing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("正在索引书签...")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if columnVisibility != .detailOnly {
                        Button(action: {
                            showingRefreshAlert = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("重新索引 Safari 书签")
                    }
                }
            }
            .frame(minWidth: 190)
        } detail: {
            Group {
                if let selection = selection, 
                   let bookmark = sites.findBookmark(id: selection),
                   let site = sites.siteForHost(bookmark.host ?? "") {
                    DetailView(site: site)
                } else {
                    DefaultView()
                }
            }
            .navigationTitle("Safari书签图标管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingLockAlert = true
                    }) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open")
                            .foregroundColor(isLocked ? .accentColor : .secondary)
                    }
                    .help(isLocked ? "当前已锁定" : "当前已解锁")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action:{
                        restartSafari()
                        interactionCount += 1
                    }, label: {
                        Image(systemName: "checkmark")
                    })
                    .disabled(isLocked)
                    .help(isLocked ? "请先解锁以进行保存" : "保存并重启 Safari")
                }
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .alert("您确定要重置所有图标吗？此操作无法撤销。", isPresented: $showingAlert) {
            Button("全部重置", role: .destructive) { resetAll() }
            Button("取消", role: .cancel) { }
        }
        .alert("确认重新索引？", isPresented: $showingRefreshAlert) {
            Button("确认") { refreshList() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("程序将重新扫描您的 Safari 书签并刷新列表。")
        }
        .alert(isLocked ? "确认解锁？" : "确认锁定？", isPresented: $showingLockAlert) {
            if isLocked {
                Button("解锁") { 
                    ImageFolderIsLocked(false)
                    touchFolderIsLocked(false)
                    isLocked = false
                    NSSound.blow?.play()
                }
            } else {
                Button("锁定") { 
                    ImageFolderIsLocked(true)
                    touchFolderIsLocked(true)
                    isLocked = true
                    NSSound.bottle?.play()
                }
            }
            Button(isLocked ? "取消" : "取消", role: .cancel) { }
        } message: {
            Text(isLocked ? "解锁后，Safari 可能会在退出时重置您的自定义图标。" : "锁定目录可以防止 Safari 在退出时自动重置您的自定义图标。若要修改图标，请先解锁。")
        }
        .onAppear {
            isLocked = checkFolderLockStatus()
        }
    }
    
    var searchResults: [Site] {
        if searchText.isEmpty {
            return sites.list
        } else {
            let query = searchText.lowercased()
            
            // 1. Search in the existing database list
            let dbResults = sites.list.filter { 
                $0.host.lowercased().contains(query) || 
                $0.domainName.lowercased().contains(query) 
            }
            
            // 2. Search in all bookmarks (including those not in cache yet)
            var bookmarkedResults: [Site] = []
            func searchBookmarks(nodes: [Bookmark]) {
                for node in nodes {
                    if let host = node.host, (node.title.lowercased().contains(query) || host.lowercased().contains(query)) {
                        // Only add if not already in results to avoid duplicates
                        if !dbResults.contains(where: { $0.host == host }) && 
                           !bookmarkedResults.contains(where: { $0.host == host }) {
                            let newSite = Site(id: -2, host: host, name: node.title, fullURL: node.fullURL, transparencyResult: 1, iconPath: AppConfig.shared.imagesURL.appendingPathComponent(node.md5 + ".png"))
                            bookmarkedResults.append(newSite)
                        }
                    }
                    if let children = node.children {
                        searchBookmarks(nodes: children)
                    }
                }
            }
            searchBookmarks(nodes: sites.bookmarkTree)
            
            return (dbResults + bookmarkedResults).sorted { $0.domainName < $1.domainName }
        }
    }
    
    
    struct SideBar_Previews: PreviewProvider {
        static var previews: some View {
            SideBarView()
                .environmentObject(Sites())
        }
    }
    
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    // Actions
    func resetAll() {
        sites.list.forEach { site in
            removeSite(site: site)
        }
        refreshList()
    }
    
    func refreshList(){
        refreshing = true;
        progress = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sites.refresh()
            progress = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            sites.refresh()
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshing = false
        }
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    @ObservedObject var sites: Sites
    @State private var isExpanded = false
    
    var body: some View {
        if let children = bookmark.children {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { child in
                    BookmarkRow(bookmark: child, sites: sites)
                }
            } label: {
                Label(bookmark.title, systemImage: bookmark.systemImage ?? "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }
        } else if bookmark.host != nil {
            NavigationLink(value: bookmark.id) {
                Label(bookmark.title, systemImage: "globe")
            }
        }
    }
}



