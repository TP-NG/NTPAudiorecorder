//
//  Audiorecorder.swift
//  Audiorecorder
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {

    @StateObject private var audioRecorder = AudioRecorderManager()
        
        var body: some View {
            VStack(spacing: 30) {
                Text(audioRecorder.isRecording ? "🎙️ Aufnahme läuft…" : "⏹️ Aufnahme gestoppt")
                    .font(.title)
                
                Button(action: {
                    if audioRecorder.isRecording {
                        audioRecorder.stopRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    Text(audioRecorder.isRecording ? "Stoppen" : "Aufnehmen")
                        .padding()
                        .frame(width: 200)
                        .background(audioRecorder.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
}
