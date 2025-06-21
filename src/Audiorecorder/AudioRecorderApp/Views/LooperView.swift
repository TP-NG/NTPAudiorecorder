//
//  LooperView.swift
//  Audiorecorder
//

// MARK: - Looper View
import SwiftUI
import AVFoundation

struct LooperView: View {
    @ObservedObject var audioRecorder: AudioRecorderManager
    @StateObject private var metronome = MetronomeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            RecorderView(audioRecorder: audioRecorder)
                .padding(.horizontal)
                .transition(.move(edge: .leading))
            
            // Metronom-Steuerung
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    MetronomeButton(
                        icon: "metronome",
                        label: metronome.isPlaying ? "Stop" : "Start",
                        color: metronome.isPlaying ? .red : .green
                    ) {
                        metronome.toggleMetronome()
                    }
                    
                    MetronomeButton(
                        icon: "play.fill",
                        label: "Count-In",
                        color: .blue
                    ) {
                        metronome.startCountIn {
                            audioRecorder.startRecording(isLoop: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Tempo-Einstellungen
                TempoControlView(metronome: metronome)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
            // Audio-Session für Mixing konfigurieren
            AudioSessionManager.configureSessionForMixing()
        }
    }
}

// MARK: - Audio Session Manager
class AudioSessionManager {
    static func configureSessionForMixing() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.mixWithOthers, .defaultToSpeaker]
            )
            try session.setActive(true)
        } catch {
            print("Fehler bei Audio-Session-Konfiguration: \(error.localizedDescription)")
        }
    }
}

// MARK: - Komponenten
struct MetronomeButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(MetronomeButtonStyle())
    }
}

struct TempoControlView: View {
    @ObservedObject var metronome: MetronomeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tempo")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(metronome.bpm) BPM")
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
            }
            
            Slider(value: Binding(
                get: { Double(metronome.bpm) },
                set: { metronome.bpm = Int($0) }
            ), in: 40...200, step: 1) {
                Text("BPM")
            } minimumValueLabel: {
                Text("40")
            } maximumValueLabel: {
                Text("200")
            }
            .accentColor(.blue)
            
            HStack {
                Text("Taktart")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("", selection: $metronome.beatsPerMeasure) {
                    ForEach(2...8, id: \.self) { beats in
                        Text("\(beats)/4")
                            .tag(beats)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
    }
}
