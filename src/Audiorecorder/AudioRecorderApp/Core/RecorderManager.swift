//
//  RecorderManager.swift
//  Audiorecorder
//

import AVFoundation
import Accelerate // For FFT calculations

class RecorderManager: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var isRecording = false
    @Published var audioURL = ""
    @Published var amplitudes: [CGFloat] = Array(repeating: 0, count: 30) // For visualization
    
    private var captureSession: AVCaptureSession?
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private let serialQueue = DispatchQueue(label: "audioQueue")
    
    func startRecording() {
        serialQueue.async {
            // Setup audio session
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
            } catch {
                print("Audio session setup error: \(error)")
                return
            }
            
            // Initialize capture session
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else { return }
            
            // Setup microphone input
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else { return }
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            // Setup audio output
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: self.serialQueue)
            
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
            }
            
            // Setup file output
            let outputFileURL = self.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            self.audioURL = outputFileURL.lastPathComponent
            
            do {
                self.assetWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: .m4a)
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
                print("AssetWriter creation error: \(error)")
                return
            }
            
            // Start capture session
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
            self.assetWriter?.finishWriting {
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
            self.captureSession = nil
            self.assetWriter = nil
            self.writerInput = nil
        }
    }
    
    // Process audio buffers for visualization
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Write to file
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
        
        // Convert to normalized amplitudes
        let amplitudes = samples.map { abs(Float($0)) / Float(Int16.max) }
        
        // Calculate RMS amplitude
        var rms: Float = 0
        vDSP_rmsqv(amplitudes, 1, &rms, vDSP_Length(amplitudes.count))
        
        // Update visualization data (rotate values)
        DispatchQueue.main.async {
            self.amplitudes.removeFirst()
            self.amplitudes.append(CGFloat(rms * 10)) // Scale for better visualization
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
