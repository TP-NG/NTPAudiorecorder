//
//  RecorderView.swift
//  Audiorecorder
//
//  Created by Administrator on 20.06.25.
//

import SwiftUI

// MARK: - Recorder View
struct RecorderView: View {
    @ObservedObject var audioRecorder: AudioRecorderManager
    
    var body: some View {
        ZStack {
            // Hintergrund mit Blur-Effekt
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack {
                // Aktuelle Amplitude als große Anzeige
                AmplitudeMeter(amplitude: audioRecorder.currentAmplitude)
                    .frame(height: 80)
                    .padding(.vertical, 10)
                
                // Dynamische Wellenform
                WaveformShape(amplitudes: audioRecorder.amplitudes)
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
