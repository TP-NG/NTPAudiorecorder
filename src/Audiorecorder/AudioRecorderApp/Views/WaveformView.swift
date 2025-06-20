//
//  WaveformView.swift
//  Audiorecorder
//
//  Created by Administrator on 20.06.25.
//

import SwiftUI

struct WaveformView: View {
    var amplitudes: [CGFloat]
        var currentAmplitude: CGFloat
        
        var body: some View {
            ZStack {
                // Hintergrund mit Blur-Effekt
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack {
                    // Aktuelle Amplitude als große Anzeige
                    AmplitudeMeter(amplitude: currentAmplitude)
                        .frame(height: 80)
                        .padding(.vertical, 10)
                    
                    // Dynamische Wellenform
                    WaveformShape(amplitudes: amplitudes)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .opacity(0.8)
                        .frame(height: 100)
                        .padding(.bottom, 10)
                }
                .padding()
            }
            .padding(.horizontal)
            .frame(height: 220)
        }
}


struct WaveformShape: Shape {
    var amplitudes: [CGFloat]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let step = width / CGFloat(amplitudes.count)
        
        // Wellenform zeichnen
        for i in 0..<amplitudes.count {
            let amplitude = amplitudes[i]
            let x = CGFloat(i) * step
            let y = midY - (amplitude * height / 2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        for i in (0..<amplitudes.count).reversed() {
            let amplitude = amplitudes[i]
            let x = CGFloat(i) * step
            let y = midY + (amplitude * height / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}

struct AmplitudeMeter: View {
    var amplitude: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Hintergrundleiste
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                // Aktuelle Amplitude
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(geometry.size.width * amplitude, geometry.size.width), height: 20)
                
                // Anzeigetext
                Text("Lautstärke: \(Int(amplitude * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}
