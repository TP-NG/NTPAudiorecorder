//
//  AudioPlayerView.swift
//  Audiorecorder
//

extension URL: Identifiable {
    public var id: String { self.path }
}

enum SortOrder {
    case ascending
    case descending

    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}

import SwiftUI

struct AudioPlayerView: View {
    @StateObject var audioPlayer = AudioPlayerManager()
    
    @State private var showingPicker = false
    @State private var volume = 0.5  // 0.0 = stumm, 1.0 = volle Lautstärke
    @State private var fileToDelete: URL?
    @State private var renamingURL: URL?
    @State private var newFilename: String = ""


    var body: some View {
        VStack(spacing: 30) {
            Text(audioPlayer.isPlaying ? "▶️ Wiedergabe läuft…" : "⏸️ Gestoppt")
                .font(.title)
            
            Button(action: {
                if audioPlayer.isPlaying {
                    audioPlayer.stopPlayback()
                } else {
                    let file = FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("aufnahme.m4a")
                    audioPlayer.startPlayback(url: file)
                }
            }) {
                Text(audioPlayer.isPlaying ? "Stoppen" : "Abspielen")
                    .padding()
                    .frame(width: 200)
                    .background(audioPlayer.isPlaying ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading) {
                Text("Lautstärke: \(Int(volume * 100)) %")
                Slider(value: $volume, in: 0.0...1.0)
                    .onChange(of: volume) {
                        audioPlayer.setPlayerVolume(Float(volume))
                    }
            }
            .padding(.horizontal)
            
            /*
            VStack {
                Button("Datei öffnen") {
                    showingPicker = true
                }
            }
            .sheet(isPresented: $showingPicker) {
                DocumentPicker { url in
                    audioPlayer.playSelectedFile(url: url)
                }
            }
            */
            Button("🔄 Sortieren") {
                audioPlayer.toggleSortOrder()
            }
            List {
                ForEach(audioPlayer.recordings, id: \.self) { file in
                    Text(file.lastPathComponent)
                        .onTapGesture {
                            audioPlayer.startPlayback(url: file)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                fileToDelete = file
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            Button {
                                renamingURL = file
                                newFilename = file.deletingPathExtension().lastPathComponent
                            } label: {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                        }
                }
            }
            
        }
        .padding()
        .onAppear {
            audioPlayer.refreshRecordings()
        }
        .confirmationDialog("Diese Datei wirklich löschen?", isPresented: Binding(
            get: { fileToDelete != nil },
            set: { if !$0 { fileToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                if let file = fileToDelete,
                   let index = audioPlayer.recordings.firstIndex(of: file) {
                    audioPlayer.deleteRecording(at: IndexSet(integer: index))
                }
                fileToDelete = nil
            }
            /*
            Button("Umbenennen") {
                if let file = fileToDelete {
                    renamingURL = file
                    newFilename = file.deletingPathExtension().lastPathComponent
                    fileToDelete = nil
                }
            }
             */
            Button("Abbrechen", role: .cancel) {
                fileToDelete = nil
            }
        }
        .sheet(item: $renamingURL) { file in
            VStack(spacing: 20) {
                Text("Neuer Name:")
                TextField("Dateiname", text: $newFilename)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Speichern") {
                    let newURL = file.deletingLastPathComponent().appendingPathComponent(newFilename).appendingPathExtension("m4a")
                    do {
                        try FileManager.default.moveItem(at: file, to: newURL)
                        audioPlayer.refreshRecordings()
                    } catch {
                        print("Fehler beim Umbenennen: \(error)")
                    }
                    renamingURL = nil
                }
                
                Button("Abbrechen", role: .cancel) {
                    renamingURL = nil
                }
            }
            .padding()
        }
        
        
    }
    

}
