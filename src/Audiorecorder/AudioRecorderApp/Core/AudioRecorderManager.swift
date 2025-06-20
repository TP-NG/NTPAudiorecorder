//
//  AudioRecorderManager.swift
//  Audiorecorder
//

import Foundation
import AVFoundation
import Accelerate // For FFT calculations

// MARK: - Audio Recorder Manager mit Looper-Funktionalität
class AudioRecorderManager: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var amplitudes: [CGFloat] = Array(repeating: 0, count: 60)
    @Published var currentAmplitude: CGFloat = 0
    @Published var recordings: [Recording] = []
    @Published var currentLoop: Int = 0
    @Published var progress: Double = 0
    
    private var captureSession: AVCaptureSession?
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private let serialQueue = DispatchQueue(label: "audioQueue")
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    @Published var exportResult: ExportResult? = nil // NEU: Für Export-Dialog

    struct Recording: Identifiable {
        let id = UUID()
        let url: URL
        let createdAt: Date
        var title: String
        
        init(url: URL) {
            self.url = url
            self.createdAt = Date()
            self.title = "Loop \(DateFormatter.localizedString(from: createdAt, dateStyle: .none, timeStyle: .short))"
        }
    }
    
    // NEU: Export-Result für Sheet
    struct ExportResult: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    
    override init() {
        super.init()
        loadRecordings()
    }
    
    // MARK: - Aufnahmefunktionen
    
    func startRecording(isLoop: Bool) {
        serialQueue.async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session error: \(error)")
                return
            }
            
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else { return }
            
            // Setup microphone
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else { return }
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            // Setup output
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: self.serialQueue)
            
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
            }
            
            // Create file URL
            let prefix = isLoop ? "loop" : "recording"
            let fileURL = self.getDocumentsDirectory().appendingPathComponent("\(prefix)_\(Date().timeIntervalSince1970).m4a")
            
            do {
                self.assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .m4a)
                let audioSettings = audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .m4a)
                self.writerInput = AVAssetWriterInput(
                    mediaType: .audio,
                    outputSettings: audioSettings
                )
                
                if let writerInput = self.writerInput,
                   let assetWriter = self.assetWriter,
                   assetWriter.canAdd(writerInput) {
                    assetWriter.add(writerInput)
                }
            } catch {
                print("AssetWriter error: \(error)")
                return
            }
            
            captureSession.startRunning()
            self.assetWriter?.startWriting()
            self.assetWriter?.startSession(atSourceTime: CMTime.zero)
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    
    func stopRecording() {
        serialQueue.async {
            self.captureSession?.stopRunning()
            self.writerInput?.markAsFinished()
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isRecording = false
                    
                    // Aufnahme zur Liste hinzufügen
                    if let url = self.assetWriter?.outputURL {
                        let recording = Recording(url: url)
                        self.recordings.append(recording)
                        self.saveRecordings()
                    }
                }
            }
            self.captureSession = nil
            self.assetWriter = nil
            self.writerInput = nil
        }
    }
    
    // MARK: - Wiedergabefunktionen
    func playRecording(at index: Int) {
        guard index < recordings.count else { return }
        
        stopPlayback()
        currentLoop = index
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            audioPlayer = try AVAudioPlayer(contentsOf: recordings[index].url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            
            // Timer für Fortschrittsanzeige
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.progress = player.currentTime / player.duration
            }
        } catch {
            print("Playback error: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        progress = 0
    }
    
    func playAllLoops() {
        guard !recordings.isEmpty else { return }
        
        stopPlayback()
        currentLoop = 0
        playNextLoop()
    }
    
    private func playNextLoop() {
        guard currentLoop < recordings.count else {
            stopPlayback()
            return
        }
        
        playRecording(at: currentLoop)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            currentLoop += 1
            playNextLoop()
        }
    }
    
    // MARK: - Dateiverwaltung
    func deleteRecording(at index: Int) {
        guard index < recordings.count else { return }
        
        let recording = recordings[index]
        
        // Datei löschen
        do {
            try FileManager.default.removeItem(at: recording.url)
        } catch {
            print("Löschen fehlgeschlagen: \(error)")
        }
        
        // Aus Liste entfernen
        recordings.remove(at: index)
        saveRecordings()
    }
    
    func renameRecording(at index: Int, newTitle: String) {
        guard index < recordings.count else { return }
        recordings[index].title = newTitle
        saveRecordings()
    }
    
    func exportAllLoops() {
        // Kombiniere alle Loops zu einer Datei
        let composition = AVMutableComposition()
        
        for recording in recordings {
            let asset = AVURLAsset(url: recording.url)
            guard let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { continue }
            
            do {
                try audioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: asset.tracks(withMediaType: .audio).first!,
                    at: composition.duration
                )
            } catch {
                print("Exportfehler: \(error)")
            }
        }
        
        // Exportiere kombinierte Datei
        let exportURL = getDocumentsDirectory().appendingPathComponent("loops_export_\(Date().timeIntervalSince1970).m4a")
        
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else { return }
        
        exporter.outputURL = exportURL
        exporter.outputFileType = .m4a
        
        exporter.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                if exporter.status == .completed {
                    // Exportierte URL speichern
                    self?.exportResult = ExportResult(url: exportURL)
                }
            }
        }
    }
    
    // MARK: - Audio Processing
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Save to file
        if writerInput?.isReadyForMoreMediaData == true {
            writerInput?.append(sampleBuffer)
        }
        
        // Process for visualization
        processAudioBuffer(sampleBuffer)
    }
    
    private func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>? = nil
        CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        let sampleCount = length / MemoryLayout<Int16>.size
        var samples = [Int16](repeating: 0, count: sampleCount)
        
        CMBlockBufferCopyDataBytes(
            blockBuffer,
            atOffset: 0,
            dataLength: length,
            destination: &samples
        )
        
        // Calculate RMS amplitude
        var floatSamples = samples.map { Float($0) / Float(Int16.max) }
        var rms: Float = 0
        vDSP_rmsqv(&floatSamples, 1, &rms, vDSP_Length(sampleCount))
        
        // Update visualization data
        DispatchQueue.main.async {
            self.currentAmplitude = CGFloat(rms * 15)
            self.amplitudes.removeFirst()
            self.amplitudes.append(self.currentAmplitude)
        }
    }
    
    // MARK: - Persistenz
    private func saveRecordings() {
        do {
            let data = try JSONEncoder().encode(recordings.map { $0.url })
            UserDefaults.standard.set(data, forKey: "audioRecordings")
        } catch {
            print("Speichern fehlgeschlagen: \(error)")
        }
    }
    
    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: "audioRecordings") else { return }
        
        do {
            let urls = try JSONDecoder().decode([URL].self, from: data)
            recordings = urls.map { Recording(url: $0) }
        } catch {
            print("Laden fehlgeschlagen: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
