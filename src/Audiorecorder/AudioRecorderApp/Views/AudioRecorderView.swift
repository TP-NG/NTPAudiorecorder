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
       @State private var recordingTime = 0
       @State private var timer: Timer?
       
       var body: some View {
           VStack(spacing: 20) {
               // Statusleiste oben
               HeaderView(
                   batteryLevel: batteryLevel,
                   isCharging: isCharging,
                   isRecording: audioRecorder.isRecording,
                   recordingTime: recordingTime
               )
               .padding(.horizontal)
               
               // Visualisierungsbereich
               WaveformView(
                   amplitudes: audioRecorder.amplitudes,
                   currentAmplitude: audioRecorder.currentAmplitude
               )
               
               // Haupt-Aufnahmeknopf
               RecordButton(isRecording: audioRecorder.isRecording) {
                   toggleRecording()
               }
               .padding(.top, 10)
               
               // Aufnahmeinformationen
               if !audioRecorder.audioURL.isEmpty {
                   VStack {
                       Text("Letzte Aufnahme")
                           .font(.headline)
                           .foregroundColor(.secondary)
                       
                       Text(audioRecorder.audioURL)
                           .font(.system(.caption, design: .monospaced))
                           .lineLimit(1)
                           .truncationMode(.middle)
                           .padding(.horizontal)
                           .padding(.vertical, 8)
                           .background(Color.gray.opacity(0.1))
                           .cornerRadius(8)
                           .contextMenu {
                               Button(action: copyToClipboard) {
                                   Label("Kopieren", systemImage: "doc.on.doc")
                               }
                           }
                   }
                   .padding()
               }
               
               Spacer()
           }
           .padding(.vertical)
           .background(
               LinearGradient(
                   gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                   startPoint: .top,
                   endPoint: .bottom
               )
               .edgesIgnoringSafeArea(.all)
           )
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
               stopTimer()
           } else {
               audioRecorder.startRecording()
               startTimer()
           }
       }
       
       private func startTimer() {
           recordingTime = 0
           timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
               recordingTime += 1
           }
       }
       
       private func stopTimer() {
           timer?.invalidate()
           timer = nil
       }
       
       private func copyToClipboard() {
           UIPasteboard.general.string = audioRecorder.audioURL
       }
       
       private func setupBatteryMonitoring() {
           UIDevice.current.isBatteryMonitoringEnabled = true
           batteryLevel = UIDevice.current.batteryLevel
           isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
           
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
               showPowerWarning = ProcessInfo.processInfo.isLowPowerModeEnabled && !isCharging
           }
           
           NotificationCenter.default.addObserver(
               forName: Notification.Name.NSProcessInfoPowerStateDidChange,
               object: nil,
               queue: .main
           ) { _ in
               showPowerWarning = ProcessInfo.processInfo.isLowPowerModeEnabled && !isCharging
           }
       }
   }

   // MARK: - Komponenten für klares Design
   struct HeaderView: View {
       let batteryLevel: Float
       let isCharging: Bool
       let isRecording: Bool
       let recordingTime: Int
       
       var body: some View {
           HStack {
               // Batterieanzeige
               HStack(spacing: 5) {
                   BatteryIcon(level: batteryLevel, isCharging: isCharging)
                   Text("\(Int(batteryLevel * 100))%")
                       .font(.system(size: 14, weight: .medium))
               }
               
               Spacer()
               
               // Aufnahmestatus
               HStack(spacing: 8) {
                   if isRecording {
                       Circle()
                           .fill(Color.red)
                           .frame(width: 10, height: 10)
                           .opacity(0.8)
                           .scaleEffect(isRecording ? 1 : 0.8)
                           .animation(
                               Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                               value: isRecording
                           )
                   }
                   
                   Text(isRecording ? "Aufnahme \(recordingTime)s" : "Bereit")
                       .font(.system(size: 14, weight: .medium))
               }
               .foregroundColor(isRecording ? .red : .secondary)
           }
           .padding(10)
           .background(Color(.tertiarySystemBackground))
           .cornerRadius(15)
       }
}

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsierender Ringeffekt während der Aufnahme
                if isRecording {
                    Circle()
                        .stroke(lineWidth: 4)
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 90, height: 90)
                        .scaleEffect(1.2)
                        .opacity(0.8)
                        .animation(
                            Animation.easeOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
                
                // Hauptknopf
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(color: isRecording ? .red.opacity(0.5) : .blue.opacity(0.5),
                            radius: 15, x: 0, y: 5)
                
                // Symbol im Knopf
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
