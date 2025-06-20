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
    // Zustandsvariable für die Auswahl
    @State private var selectedRecording: URL? = nil
    
    @State private var showingPicker = false
    @State private var volume = 0.5  // 0.0 = stumm, 1.0 = volle Lautstärke
    
    @State private var fileToDelete: URL?
    @State private var renamingURL: URL?
    @State private var newFilename = ""
    @FocusState private var isRenameFieldFocused: Bool
    @State private var showRenameError = false
    
    // In AudioPlayerManager class
    private var resumePosition: TimeInterval = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    playbackStatus
                    playbackControls
                    progressView
                    volumeControl
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                
                // File list with improved UX
                fileList
                
            }
            .navigationTitle("Audioaufnahmen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortButton
                }
            }
            
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: audioPlayer.refreshRecordings)
        .confirmationDialog("Datei löschen", isPresented: Binding(
            get: { fileToDelete != nil },
            set: { if !$0 { fileToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                deleteSelectedFile()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(item: $renamingURL) { file in
            renameDialog(for: file)
        }
        .alert("Ungültiger Name", isPresented: $showRenameError) {
            Button("OK") {}
        } message: {
            Text("Bitte geben Sie einen gültigen Dateinamen ein.")
        }
        
    }
    
    // MARK: - Subviews
    
    private var playbackStatus: some View {
        HStack {
            Image(systemName: audioPlayer.isPlaying ? "waveform" : "speaker.slash")
                .foregroundColor(audioPlayer.isPlaying ? .green : .gray)
            
            Text(audioPlayer.isPlaying ? "Wiedergabe läuft" : "Pausiert")
                .font(.subheadline)
                .foregroundColor(audioPlayer.isPlaying ? .primary : .secondary)
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button(action: audioPlayer.skipBackward) {
                Image(systemName: "gobackward.15")
                    .font(.title)
            }
            
            Button(action: togglePlayback) {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.blue)
            }
            
            Button(action: audioPlayer.skipForward) {
                Image(systemName: "goforward.15")
                    .font(.title)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }
   
    private var progressView: some View {
        VStack(spacing: 4) {
            Slider(value: $audioPlayer.playbackProgress, in: 0...1)
                .accentColor(.blue)
                .disabled(!audioPlayer.isPlaying)
            
            HStack {
                Text(audioPlayer.currentTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(audioPlayer.durationString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
    
    private var volumeControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.secondary)
            
            Slider(value: $volume, in: 0.0...1.0)
                .onChange(of: volume) {
                    audioPlayer.setPlayerVolume(Float(volume))
                }
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.secondary)
        }
    }
    
    private var sortButton: some View {
        Button(action: {
            audioPlayer.toggleSortOrder()
        }) {
            Label("Sortieren", systemImage: "arrow.up.arrow.down")
        }
        .buttonStyle(.bordered)
    }
    
    private var fileList: some View {
        List {
            if audioPlayer.recordings.isEmpty {
                emptyStateView
            }
            
            ForEach(audioPlayer.recordings, id: \.self) { file in
                fileRow(for: file)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        swipeActions(for: file)
                    }
                    .listRowBackground(
                        audioPlayer.nowPlayingURL == file ? Color.blue.opacity(0.1) : Color.clear
                    )
            }
        }
        .listStyle(.plain)
    }
    
    private func fileRow(for file: URL) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform")
                .foregroundColor(audioPlayer.nowPlayingURL == file ? .blue : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.deletingPathExtension().lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(file.creationDateString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if audioPlayer.nowPlayingURL == file {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            audioPlayer.startPlayback(url: file)
        }
    }
    
    private func swipeActions(for file: URL) -> some View {
        Group {
            Button {
                renamingURL = file
                newFilename = file.deletingPathExtension().lastPathComponent
            } label: {
                Label("Umbenennen", systemImage: "pencil")
            }
            .tint(.orange)
            
            Button(role: .destructive) {
                fileToDelete = file
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.audio")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Keine Aufnahmen")
                .font(.headline)
            Text("Erstellen Sie Ihre erste Aufnahme")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .listRowSeparator(.hidden)
    }
    
    private func renameDialog(for file: URL) -> some View {
        NavigationView {
            Form {
                Section {
                    TextField("Dateiname", text: $newFilename)
                        .focused($isRenameFieldFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isRenameFieldFocused = true
                            }
                        }
                        .submitLabel(.done)
                        .onSubmit(saveRename)
                } header: {
                    Text("Neuer Name")
                } footer: {
                    Text("Ohne Dateiendung (.m4a)")
                }
            }
            .navigationTitle("Datei umbenennen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        renamingURL = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveRename()
                    }
                    .disabled(newFilename.isEmpty)
                }
            }
        }
    }
    
    
    // MARK: - Actions
    
    // In togglePlayback method in AudioPlayerView
    private func togglePlayback() {
        if audioPlayer.isPlaying {
            audioPlayer.pausePlayback()
        } else if let currentURL = audioPlayer.nowPlayingURL {
            audioPlayer.startPlayback(url: currentURL)
        } else if let firstRecording = audioPlayer.recordings.first {
            audioPlayer.startPlayback(url: firstRecording)
        }
    }
    
    private func deleteSelectedFile() {
        guard let file = fileToDelete,
              let index = audioPlayer.recordings.firstIndex(of: file) else {
            fileToDelete = nil
            return
        }
        
        // Stop playback if deleting currently playing file
        if audioPlayer.nowPlayingURL == file {
            audioPlayer.stopPlayback()
        }
        
        audioPlayer.deleteRecording(at: IndexSet(integer: index))
        fileToDelete = nil
    }
    
    private func saveRename() {
        guard !newFilename.isEmpty else {
            showRenameError = true
            return
        }
        
        guard let file = renamingURL else { return }
        
        let newURL = file.deletingLastPathComponent()
            .appendingPathComponent(newFilename)
            .appendingPathExtension("m4a")
        
        do {
            try FileManager.default.moveItem(at: file, to: newURL)
            audioPlayer.refreshRecordings()
            
            // Update now playing reference if needed
            if audioPlayer.nowPlayingURL == file {
                audioPlayer.nowPlayingURL = newURL
            }
        } catch {
            print("Fehler beim Umbenennen: \(error)")
        }
        
        renamingURL = nil
    }
}

// MARK: - Extensions

extension URL {
    var creationDateString: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let creationDate = attributes[.creationDate] as? Date else {
            return "Unbekanntes Datum"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}
