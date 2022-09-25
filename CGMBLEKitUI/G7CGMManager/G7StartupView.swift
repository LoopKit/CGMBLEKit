//
//  G7StartupView.swift
//  CGMBLEKitUI
//
//  Created by Pete Schwamb on 9/24/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation
import SwiftUI

struct G7StartupView: View {
    var didContinue: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            Text(LocalizedString("Dexcom G7", comment: "Title on WelcomeView"))
                .font(.largeTitle)
                .fontWeight(.semibold)
            Image(frameworkImage: "g7", decorative: true)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
            Text(LocalizedString("Loop can be used with G7 sensors in concert with the official Dexcom G7 App. Pairing, calibration, and other sensor management will be done in the Dexcom G7 App, and Loop will just listen for new CGM readings.", comment: "Descriptive text on G7StartupView"))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                self.didContinue?()
            }) {
                Text(LocalizedString("I Understand", comment:"Button title for starting setup"))
                    .actionButtonStyle(.primary)
            }
        }
        .padding()
        .environment(\.horizontalSizeClass, .compact)
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            G7StartupView()
        }
        .previewDevice("iPod touch (7th generation)")
    }
}
