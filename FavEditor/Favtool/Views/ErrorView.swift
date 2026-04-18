//
//  ErrorView.swift
//  Favtool
//
//  Created by Nicola Di Gregorio on 27/11/22.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        Text("FavEditor need access to image folder, grant access and restart FavEditor")
        Button {
            showSavePanel()
        } label: {
            Text("TeGrantAccess")
        }

    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
