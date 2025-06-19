//
//  AudioPlayerManager.swift
//  Audiorecorder
//

import Foundation
import AVFoundation

class AudioPlayerManager: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    @Published var isPlaying = false
    
    @Published var recordings: [URL] = []
    
    var isAscending: Bool = true  // steuert die Sortierreihenfolge

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
    
    func startPlayback(url: URL) {
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            print("Fehler bei der Wiedergabe: \(error)")
        }
    }
    
    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
    }
    
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
    
    func setPlayerVolume(_ value: Float) {
        player?.volume = value
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

