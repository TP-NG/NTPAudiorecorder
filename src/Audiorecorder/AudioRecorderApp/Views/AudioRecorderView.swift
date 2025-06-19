//
//  Audiorecorder.swift
//  Audiorecorder
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {

    @StateObject private var audioRecorder = AudioRecorderManager()
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var showPowerWarning = false

        var body: some View {
            VStack() {
                Text("🔋 Batterie: \(Int(batteryLevel * 100)) %")
                    .font(.caption)
                    .foregroundColor(batteryLevel < 0.2 ? .red : .primary)
                
                Text(audioRecorder.isRecording ? "🎙️ Aufnahme läuft…" : "⏹️ Aufnahme gestoppt")
                    .font(.footnote)
                
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
        
                
                // Visuallisieren
                
                Text(audioRecorder.audioURL.isEmpty ? "Noch keine Aufnahme vorhanden." : "Audio URL: \(audioRecorder.audioURL)")
                    .font(.caption)
            }
            .padding()
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true

                batteryLevel = UIDevice.current.batteryLevel

                let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
                if ProcessInfo.processInfo.isLowPowerModeEnabled && !isCharging {
                    showPowerWarning = true
                }

                NotificationCenter.default.addObserver(
                    forName: .NSProcessInfoPowerStateDidChange,
                    object: nil,
                    queue: .main
                ) { _ in
                    
                    batteryLevel = UIDevice.current.batteryLevel
                    
                    let isChargingNow = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
                    showPowerWarning = ProcessInfo.processInfo.isLowPowerModeEnabled && !isChargingNow
                }
            }
            .alert("⚠️ Stromsparmodus erkannt", isPresented: $showPowerWarning) {
                Button("OK", role: .cancel) { showPowerWarning = false }
            } message: {
                Text("Um Unterbrechungen bei der Aufnahme zu vermeiden, empfehlen wir das Gerät an ein Ladegerät anzuschließen.")
            }
        }
    
}
