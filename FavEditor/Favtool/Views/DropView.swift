//
//  DropView.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 18/11/22.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropView: View {
    
    @EnvironmentObject var sites : Sites;
    
    @State var icon = "tray.and.arrow.down";
    @State var color  = Color(.gray);
    @State var text  = "将图片拖拽至此";
    
    var site : Site;
    @Binding var ischanged : Bool;
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(.secondary.opacity(0.3))
            
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 32))
                    .foregroundColor(color == Color(.gray) ? .secondary : color)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 140, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.02))
        )
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
            dropAction(providers: providers, site: site)
        }
    }
    
    func dropAction(providers: [NSItemProvider], site: Site) -> Bool {
        // 1. Try to load as an image (this handles direct image dragging from Safari)
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: NSImage.self) }) {
            _ = provider.loadObject(ofClass: NSImage.self) { object, error in
                if let image = object as? NSImage {
                    DispatchQueue.main.async {
                        updateIcon(site: site) {
                            saveImage(image, for: site)
                        }
                    }
                }
            }
            return true
        }
        
        // 2. Fallback to URL (handles files from Finder)
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) {
            _ = provider.loadObject(ofClass: URL.self) { object, error in
                if let url = object {
                    DispatchQueue.main.async {
                        updateIcon(site: site) {
                            copyImage(url, for: site)
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func updateIcon(site: Site, action: () -> Void) {
        touchFolderIsLocked(false)
        ImageFolderIsLocked(false)
        
        action()
        setIconIsOnChache(site: site)
        
        ischanged.toggle()
        icon = "checkmark.seal.fill"
        color = Color(.systemGreen)
        text = "已就绪，请重启 Safari 以同步更改"
        touchFolderIsLocked(true)
    }
}


