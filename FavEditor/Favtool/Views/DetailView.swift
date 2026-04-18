//
//  DetailView.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 18/11/22.
//

import SwiftUI
import AppKit

struct DetailView: View {
    @EnvironmentObject var sites: Sites
    @State private var selected = 1
    @State var change: Bool = false
    var site: Site
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    HStack(alignment: .center, spacing: 20) {
                        
                        AsyncImage(url: change ? URL(string: site.iconPath.absoluteString + "?v=" + UUID().uuidString) : site.iconPath) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "globe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        .id(change)
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(site.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            Text(site.fullURL ?? site.host)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Configuration Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("配置信息")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        GroupBox {
                            VStack(spacing: 0) {
                                
                                HStack {
                                    Label("网址", systemImage: "link")
                                        .font(.body)
                                    Spacer()
                                    Text(site.fullURL ?? site.host)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: 200)
                                        .help(site.fullURL ?? site.host)
                                }
                                .padding(.vertical, 8)
                                
                                Divider()
                                
                                HStack {
                                    Label("MD5 散列值", systemImage: "number")
                                        .font(.body)
                                    Spacer()
                                    Text(site.md5)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: 200)
                                        .help(site.md5)
                                }
                                .padding(.vertical, 8)
                                
                                Divider()
                                
                                HStack {
                                    Label("本地文件", systemImage: "folder")
                                        .font(.body)
                                    Spacer()
                                    
                                    let pathExists = FileManager.default.fileExists(atPath: site.iconPath.path)
                                    
                                    if pathExists {
                                        Button(action: {
                                            NSWorkspace.shared.activateFileViewerSelecting([site.iconPath])
                                        }) {
                                            Text(site.iconPath.path)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.accentColor)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                                .frame(maxWidth: 200)
                                                .underline()
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help(site.iconPath.path)
                                    } else {
                                        Text("暂无缓存")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal, 8)
                        }
                        .groupBoxStyle(PlainGroupBoxStyle())
                    }
                    
                    // Drop Zone Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("自定义图标")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        DropView(site: site, ischanged: $change)
                    }
                }
                .padding(32)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
}


struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        }
    }
}


