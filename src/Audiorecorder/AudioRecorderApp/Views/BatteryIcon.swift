//
//  BatteryIcon.swift
//  Audiorecorder
//
//  Created by Administrator on 20.06.25.
//

import SwiftUI

struct BatteryIcon: View {
    let level: Float
    let isCharging: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(lineWidth: 1.5)
                .frame(width: 28, height: 14)
            
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(batteryColor)
                    .frame(width: 24 * CGFloat(level), height: 10)
                
                Spacer(minLength: 0)
            }
            .padding(2)
            
            // Batterie-Tipp
            Rectangle()
                .frame(width: 3, height: 6)
                .offset(x: 15.5)
            
            // Ladesymbol
            if isCharging {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 8, height: 8)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 28, height: 14)
    }
    
    private var batteryColor: Color {
        switch level {
        case 0..<0.2: return .red
        case 0.2..<0.5: return .yellow
        default: return .green
        }
    }
}
