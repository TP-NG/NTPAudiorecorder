//
//  Audiorecorder.swift
//  Audiorecorder
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @StateObject private var audioRecorder = RecorderManager()
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var showPowerWarning = false
    @State private var isCharging = false

    var body: some View {
        VStack {
            // Battery indicator
            HStack {
                BatteryIcon(level: batteryLevel, isCharging: isCharging)
                Text("\(Int(batteryLevel * 100))%")
                    .font(.caption)
                    .foregroundColor(batteryLevel < 0.2 ? .red : .primary)
                Spacer()
                Text(audioRecorder.isRecording ? "🎙️ Aufnahme läuft" : "⏹️ Aufnahme gestoppt")
                    .font(.caption)
            }
            .padding(.horizontal)
            
            // Visualization
            WaveformView(amplitudes: audioRecorder.amplitudes)
                .frame(height: 150)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .padding(.vertical)
            
            // Record button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red : Color.green)
                        .frame(width: 70, height: 70)
                        .shadow(radius: 5)
                    
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 20)
            
            // Recording info
            if !audioRecorder.audioURL.isEmpty {
                VStack {
                    Text("Letzte Aufnahme:")
                        .font(.headline)
                    Text(audioRecorder.audioURL)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: setupBatteryMonitoring)
        .alert(isPresented: $showPowerWarning) {
            Alert(
                title: Text("⚠️ Stromsparmodus"),
                message: Text("Um Unterbrechungen bei der Aufnahme zu vermeiden, empfehlen wir das Gerät an ein Ladegerät anzuschließen."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        } else {
            audioRecorder.startRecording()
        }
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        
        // Update power warning state
        updatePowerWarning()
        
        // Set up observers
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            batteryLevel = UIDevice.current.batteryLevel
        }
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            let state = UIDevice.current.batteryState
            isCharging = state == .charging || state == .full
            updatePowerWarning()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            updatePowerWarning()
        }
    }
    
    private func updatePowerWarning() {
        showPowerWarning = ProcessInfo.processInfo.isLowPowerModeEnabled && !isCharging
    }
    
}
