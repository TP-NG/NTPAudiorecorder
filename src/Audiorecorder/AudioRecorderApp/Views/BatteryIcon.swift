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
            RoundedRectangle(cornerRadius: 2)
                .stroke(lineWidth: 1)
                .frame(width: 24, height: 12)
            
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(batteryColor)
                    .frame(width: 20 * CGFloat(level), height: 10)
                
                Spacer(minLength: 0)
            }
            .padding(1)
            
            // Battery tip
            Rectangle()
                .frame(width: 2, height: 4)
                .offset(x: 13)
            
            // Charging icon
            if isCharging {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 8, height: 8)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 24, height: 12)
    }
    
    private var batteryColor: Color {
        switch level {
        case 0..<0.2: return .red
        case 0.2..<0.5: return .yellow
        default: return .green
        }
    }
}
