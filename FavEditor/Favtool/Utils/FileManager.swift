//
//  FileManager.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 16/11/22.
//

import Foundation
import AppKit

//partial Paths
func showSavePanel(path: URL) {
    let openPanel = NSOpenPanel()
    openPanel.title = "授权访问"
    openPanel.directoryURL = path
    openPanel.canChooseDirectories = true
    openPanel.message = "请点击“授权”以允许程序修改 Safari 图标缓存"
    openPanel.prompt = "授权"
    openPanel.showsTagField = false
    openPanel.runModal()
}

func copyImage(_ from: URL, for site: Site) {
    let fileManager = FileManager.default
    let destination = AppConfig.shared.imagesURL.appendingPathComponent(site.md5 + ".png")
    do {
        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(at: from, to: destination)
        NSSound.blow?.play()
    } catch {
        print("Error copying file: \(error)")
        NSSound.basso?.play()
    }
}

func saveImage(_ image: NSImage, for site: Site) {
    let croppedImage = trimTransparentEdges(image: image)
    guard let tiffData = croppedImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Error: Could not convert image to PNG")
        NSSound.basso?.play()
        return
    }
    
    let destination = AppConfig.shared.imagesURL.appendingPathComponent(site.md5 + ".png")
    do {
        try? FileManager.default.removeItem(at: destination)
        try pngData.write(to: destination)
        NSSound.blow?.play()
    } catch {
        print("Error saving image: \(error)")
        NSSound.basso?.play()
    }
}

func trimTransparentEdges(image: NSImage) -> NSImage {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return image }
    
    let width = cgImage.width
    let height = cgImage.height
    
    let bytesPerRow = width * 4
    let size = height * bytesPerRow
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
    buffer.initialize(repeating: 0, count: size)
    defer { 
        buffer.deinitialize(count: size)
        buffer.deallocate() 
    }
    
    guard let context = CGContext(data: buffer,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    
    var lowX = width
    var lowY = height
    var highX = 0
    var highY = 0
    
    for y in 0..<height {
        for x in 0..<width {
            let alpha = buffer[(y * width + x) * 4 + 3]
            if alpha > 0 {
                if x < lowX { lowX = x }
                if x > highX { highX = x }
                if y < lowY { lowY = y }
                if y > highY { highY = y }
            }
        }
    }
    
    if lowX > highX || lowY > highY {
        return image
    }
    
    let cropWidth = highX - lowX + 1
    let cropHeight = highY - lowY + 1
    // CG coordinates: (0,0) is bottom-left. 
    // Data buffer: (0,0) is top-left.
    // If top-most non-transparent pixel is at buffer row lowY, 
    // its CG y-coordinate is (height - 1 - highY).
    let cropRect = CGRect(x: CGFloat(lowX), y: CGFloat(height - 1 - highY), width: CGFloat(cropWidth), height: CGFloat(cropHeight))
    
    if let croppedCgImage = cgImage.cropping(to: cropRect) {
        return NSImage(cgImage: croppedCgImage, size: NSSize(width: cropWidth, height: cropHeight))
    }
    
    return image
}

@discardableResult
func ImageFolderIsLocked(_ state: Bool) -> String {
    let folderPath = AppConfig.shared.imagesURL.path
    do {
        try FileManager.default.setAttributes([FileAttributeKey.immutable: state], ofItemAtPath: folderPath)
    } catch {
        print("Error locking image folder: \(error)")
        NSSound.basso?.play()
        return error.localizedDescription
    }
    return "操作成功"
}

@discardableResult
func touchFolderIsLocked(_ state: Bool) -> String {
    let folderPath = AppConfig.shared.touchIconsCacheURL.path
    do {
        try FileManager.default.setAttributes([FileAttributeKey.immutable: state], ofItemAtPath: folderPath)
    } catch {
        print("Error locking touch icon folder: \(error)")
        NSSound.basso?.play()
        return error.localizedDescription
    }
    return "操作成功"
}

func checkFolderLockStatus() -> Bool {
    let folderPath = AppConfig.shared.imagesURL.path
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: folderPath)
        return attributes[.immutable] as? Bool ?? false
    } catch {
        return false
    }
}

func createFolder(path: URL) {
    do {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error creating directory: \(error)")
    }
}

func removeItems(path: URL) {
    do {
        try FileManager.default.removeItem(at: path)
    } catch {
        print("Error removing items: \(error)")
    }
}

