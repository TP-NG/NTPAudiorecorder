//
//  AudiorecorderApp.swift
//  Audiorecorder
//

import SwiftUI
import AVFoundation

@main
struct AudiorecorderApp: App {

    init() {
            configureAudioSession()
        }

    func configureAudioSession() {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
            } catch {
                print("Fehler beim Konfigurieren der AVAudioSession: \(error)")
            }
        }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
