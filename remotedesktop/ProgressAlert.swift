//
//  ProgressAlert.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 10/2/2024.
//

import Foundation
import SwiftUI

public struct ProgressAlert: View {
    public var closeAction: () -> Void

    public init(closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor(red: 0.05, green: 0.64, blue: 0.82, alpha: 1))))
                    Text("Loading...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                /*Divider()
                Button(action: closeAction, label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(red: 0.05, green: 0.64, blue: 0.82, alpha: 1)))
                })
                .foregroundColor(.black)*/
            }
            .padding(.vertical, 25)
            .frame(maxWidth: 270)
            .background(BlurView(style: .systemMaterial))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.primary.opacity(0.35)
        )
        .edgesIgnoringSafeArea(.all)
    }
}

public struct BlurView: UIViewRepresentable {
    public var style: UIBlurEffect.Style

    public func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
