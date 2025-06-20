//
//  AudioPlayerManager.swift
//  Audiorecorder
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    
    private var progressTimer: AnyCancellable?
    
    // In AudioPlayerManager class
    private var resumePosition: TimeInterval = 0

    @Published var isPlaying = false
    
    @Published var recordings: [URL] = []
    
    var isAscending: Bool = true  // steuert die Sortierreihenfolge
   
    @Published var playbackProgress: Double = 0
    @Published var currentTimeString: String = "00:00"
    @Published var durationString: String = "00:00"
    @Published var nowPlayingURL: URL?
    
    override init() {
        super.init()
        refreshRecordings()
    }
    
    // MARK: - Playback Controls
        
    func startPlayback(url: URL) {
        // If resuming same file
        if nowPlayingURL == url, player != nil {
            player?.currentTime = resumePosition
            player?.play()
            isPlaying = true
            setupProgressUpdates()
            return
        }
        
        // New file or no existing player
        stopPlayback()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            player?.currentTime = resumePosition
            player?.play()
            
            isPlaying = true
            nowPlayingURL = url
            setupProgressUpdates()
        } catch {
            print("Playback error: \(error)")
        }
    }

    func stopPlayback() {
        resumePosition = 0
        player?.stop()
        player = nil
        isPlaying = false
        nowPlayingURL = nil
        playbackProgress = 0
        currentTimeString = "00:00"
        durationString = "00:00"
        progressTimer?.cancel()
    }
    
    func pausePlayback() {
        guard let player = player else { return }
        resumePosition = player.currentTime
        player.pause()
        isPlaying = false
        progressTimer?.cancel()
    }
    
    func skipForward() {
           guard let player = player else { return }
           player.currentTime = min(player.duration, player.currentTime + 15)
           updateProgressDisplay()
       }
       
       func skipBackward() {
           guard let player = player else { return }
           player.currentTime = max(0, player.currentTime - 15)
           updateProgressDisplay()
       }
       
    
    
    func setPlayerVolume(_ value: Float) {
        player?.volume = value
    }
    
     func sortRecordings() {
         recordings = recordings
             .filter { $0.pathExtension == "m4a" }
             .sorted {
                 isAscending
                     ? $0.lastPathComponent < $1.lastPathComponent
                     : $0.lastPathComponent > $1.lastPathComponent
             }
     }

     func toggleSortOrder() {
         isAscending.toggle()
         sortRecordings()
     }
    
    // MARK: - Private Helpers
    
    private func creationDate(for url: URL) -> Date {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                return attributes[.creationDate] as? Date ?? Date.distantPast
            } catch {
                return Date.distantPast
            }
        }
        
        private func setupProgressUpdates() {
            progressTimer?.cancel()
            progressTimer = Timer.publish(every: 0.25, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateProgressDisplay()
                }
        }
        
        private func updateProgressDisplay() {
            guard let player = player else { return }
            
            playbackProgress = player.duration > 0 ? player.currentTime / player.duration : 0
            currentTimeString = formatTime(player.currentTime)
            durationString = formatTime(player.duration)
        }
        
        private func formatTime(_ time: TimeInterval) -> String {
            guard time.isFinite else { return "00:00" }
            let totalSeconds = Int(time)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    
    
    
    // MARK: - File Management
        
    
    func listSavedRecordings() -> [URL] {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "m4a" }
        } catch {
            print("Fehler beim Lesen des Verzeichnisses: \(error)")
            return []
        }
    }
    
    func sortedListSavedRecordings() -> [URL] {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            let audioFiles = files.filter { $0.pathExtension == "m4a" }
            
            let sortedFiles = try audioFiles.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2  // Neueste zuerst
            }
            
            return sortedFiles
        } catch {
            print("Fehler beim Lesen oder Sortieren des Verzeichnisses: \(error)")
            return []
        }
    }
    
   
    func refreshRecordings() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)
            let audioFiles = files.filter { $0.pathExtension == "m4a" }
            recordings = try audioFiles.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2  // Neueste zuerst
            }
            
        } catch {
            print("Fehler beim Laden der Aufnahmen: \(error)")
            recordings = []
        }
    }
    
    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let fileURL = recordings[index]
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Fehler beim Löschen der Datei: \(error)")
            }
        }
        refreshRecordings()
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

