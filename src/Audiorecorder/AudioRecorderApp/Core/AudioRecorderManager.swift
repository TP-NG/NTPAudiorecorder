//
//  AudioRecorderManager.swift
//  Audiorecorder
//
//  Created by Administrator on 16.06.25.
//

import Foundation
import AVFoundation

class AudioRecorderManager: NSObject, ObservableObject {
    private var recorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var audioURL = ""
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let filename = formatter.string(from: Date()) + ".m4a"
            
            let url = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            
            audioURL = url.path
            
            print("Aufnahmepfad: \(audioURL)")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            if recorder?.record() == true {
                isRecording = true
            } else {
                print("Fehler: Recorder konnte nicht starten.")
                recorder = nil
                isRecording = false
            }
        } catch {
            print("Fehler beim Starten der Aufnahme: \(error)")
            recorder = nil
            isRecording = false
        }
    }

    func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
    }
}
