//
//  DefaultView.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 27/11/22.
//

import SwiftUI



struct DefaultView: View {
    @EnvironmentObject var sites : Sites
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .center, spacing: 18) {
                Image(systemName: "safari")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary.opacity(0.12))
                
                VStack(spacing: 10) {
                    Text("请选择一个书签")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("从左侧目录中选择一个书签开始编辑")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 250) // Constrain width to ensure nice wrapping and centering
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}


struct DefaultView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultView().environmentObject(Sites())
    }
}
