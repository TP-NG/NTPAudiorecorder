//
//  MetronomeManager.swift
//  Audiorecorder
//
import SwiftUI
import Foundation
import AVFoundation

// MARK: - Verbesserter Metronom Manager mit Audio-Session-Handling
class MetronomeManager: ObservableObject {
    @Published var isPlaying = false
    @Published var bpm: Int = 120
    @Published var beatsPerMeasure: Int = 4
    
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var buffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?
    private var timer: DispatchSourceTimer?
    private var currentBeat = 0
    private var audioSessionConfigured = false
    
    init() {
        setupAudioEngine()
        setupAudioSession()
        setupInterruptionObserver()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.mixWithOthers, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            audioSessionConfigured = true
        } catch {
            print("Metronom Audio-Session Fehler: \(error.localizedDescription)")
        }
    }
    
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Unterbrechung gestartet
            if isPlaying {
                stop()
            }
            
        case .ended:
            // Unterbrechung beendet
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // Session neu aktivieren
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    if isPlaying {
                        start()
                    }
                } catch {
                    print("Fehler beim Reaktivieren der Audio-Session: \(error)")
                }
            }
            
        default: break
        }
    }
    
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        
        guard let engine = engine,
              let player = player,
              let clickURL = Bundle.main.url(forResource: "click2", withExtension: "wav"),
              let accentURL = Bundle.main.url(forResource: "click1", withExtension: "wav") else {
            print("Kann Audio-Engine nicht initialisieren oder Sounddateien nicht finden.")
            return
        }
        
        do {
            let clickFile = try AVAudioFile(forReading: clickURL)
            let accentFile = try AVAudioFile(forReading: accentURL)
            
            let commonFormat = clickFile.processingFormat
            buffer = AVAudioPCMBuffer(pcmFormat: commonFormat, frameCapacity: AVAudioFrameCount(clickFile.length))
            accentBuffer = AVAudioPCMBuffer(pcmFormat: commonFormat, frameCapacity: AVAudioFrameCount(accentFile.length))
            
            try clickFile.read(into: buffer!)
            try accentFile.read(into: accentBuffer!)
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: commonFormat)
            
            try engine.start()
        } catch {
            print("Metronom Fehler: \(error.localizedDescription)")
        }
    }
    
    func toggleMetronome() {
        isPlaying ? stop() : start()
    }
    
    func start() {
        guard !isPlaying else { return }
        
        // Audio-Session sicherstellen
        if !audioSessionConfigured {
            setupAudioSession()
        }
        
        isPlaying = true
        currentBeat = 0
        startTimer()
    }
    
    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
    }
    
    private func startTimer() {
        let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
        timer = DispatchSource.makeTimerSource(queue: queue)
        
        let interval = 60.0 / Double(bpm)
        
        timer?.schedule(
            deadline: .now(),
            repeating: interval,
            leeway: .milliseconds(10)
        )
        
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playClick()
            }
        }
        
        timer?.resume()
    }
    
    private func playClick() {
        guard let player = player,
              let buffer = buffer,
              let accentBuffer = accentBuffer else { return }
        
        // Stoppe eventuell laufende Wiedergabe
        player.stop()
        
        if currentBeat == 0 {
            player.scheduleBuffer(accentBuffer, at: nil, options: [])
        } else {
            player.scheduleBuffer(buffer, at: nil, options: [])
        }
        
        player.play()
        currentBeat = (currentBeat + 1) % beatsPerMeasure
    }
    
    func startCountIn(completion: @escaping () -> Void) {
        stop()
        var beatsRemaining = beatsPerMeasure
        currentBeat = 0
        
        let queue = DispatchQueue(label: "countin.timer", qos: .userInteractive)
        let countInTimer = DispatchSource.makeTimerSource(queue: queue)
        
        let interval = 60.0 / Double(bpm)
        
        countInTimer.schedule(
            deadline: .now(),
            repeating: interval,
            leeway: .milliseconds(10)
        )
        
        countInTimer.setEventHandler {
            DispatchQueue.main.async {
                self.playClick()
                beatsRemaining -= 1
                
                if beatsRemaining == 0 {
                    countInTimer.cancel()
                    completion()
                }
            }
        }
        
        countInTimer.resume()
    }
}

// MARK: - Button Animation
struct MetronomeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
