//
//  WaveformView.swift
//  Audiorecorder
//
//  Created by Administrator on 20.06.25.
//

import SwiftUI

struct WaveformView: View {
    var amplitudes: [CGFloat]
      
      var body: some View {
          GeometryReader { geometry in
              ZStack {
                  // Background grid
                  Path { path in
                      let midY = geometry.size.height / 2
                      path.move(to: CGPoint(x: 0, y: midY))
                      path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                  }
                  .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                  
                  // Waveform
                  Path { path in
                      let width = geometry.size.width
                      let height = geometry.size.height
                      let midY = height / 2
                      let step = width / CGFloat(amplitudes.count)
                      
                      path.move(to: CGPoint(x: 0, y: midY))
                      
                      for (index, amplitude) in amplitudes.enumerated() {
                          let x = CGFloat(index) * step
                          let y = midY - (amplitude * height / 2)
                          path.addLine(to: CGPoint(x: x, y: y))
                      }
                      
                      for (index, amplitude) in amplitudes.enumerated().reversed() {
                          let x = CGFloat(index) * step
                          let y = midY + (amplitude * height / 2)
                          path.addLine(to: CGPoint(x: x, y: y))
                      }
                      
                      path.closeSubpath()
                  }
                  .fill(LinearGradient(
                      gradient: Gradient(colors: [.blue.opacity(0.5), .purple.opacity(0.7)]),
                      startPoint: .top,
                      endPoint: .bottom
                  ))
              }
          }
      }
}
