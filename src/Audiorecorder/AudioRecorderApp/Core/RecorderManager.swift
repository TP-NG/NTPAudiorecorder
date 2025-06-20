//
//  RecorderManager.swift
//  Audiorecorder
//

import AVFoundation
import Accelerate // For FFT calculations

class RecorderManager: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var isRecording = false
        @Published var audioURL = ""
        @Published var amplitudes: [CGFloat] = Array(repeating: 0, count: 60)
        @Published var currentAmplitude: CGFloat = 0
        
        private var captureSession: AVCaptureSession?
        private var assetWriter: AVAssetWriter?
        private var writerInput: AVAssetWriterInput?
        private let serialQueue = DispatchQueue(label: "audioQueue")
        
        func startRecording() {
            serialQueue.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.record)
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
                let fileURL = self.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
                self.audioURL = fileURL.lastPathComponent
                
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
        
        private func getDocumentsDirectory() -> URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
}
