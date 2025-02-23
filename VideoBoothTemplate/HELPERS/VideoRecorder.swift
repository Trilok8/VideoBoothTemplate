//
//  VideoRecorder.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 17/02/2025.
//

import AVFoundation
import UIKit

protocol VideoRecorderDelegate: AnyObject {
    func didFinishRecording(url: URL?)
    func didFailRecording(error: Error?)
    func didSetupPreviewLayer(_previewLayer: AVCaptureVideoPreviewLayer)
}

class VideoRecorder: NSObject,AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice!
    private var audioDevice: AVCaptureDevice!
    private var videoInput: AVCaptureDeviceInput!
    private var audioInput: AVCaptureDeviceInput!
    private var isStoppingRecording = false
    weak var delegate: VideoRecorderDelegate?
    private var isSessionReady = false // New flag to check if session is ready
    
    override init() {
        super.init()
        cameraSetup()
    }
    
    public func cameraSetup(){
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Error: Cannot access camera")
            return
        }
        
        videoDevice = device
        videoInput = input
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            self.audioDevice = audioDevice
            self.audioInput = audioInput
            captureSession.addInput(audioInput)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Start the session in the background
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            // After starting the session, update the isSessionReady flag
            DispatchQueue.main.async {
                self.isSessionReady = true
                print("Did setup preview layer in background thread main async")
                self.delegate?.didSetupPreviewLayer(_previewLayer: self.previewLayer)
            }
        }
        
        DispatchQueue.main.async {
            print("Did setup preview layer out of background thread main async")
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.videoGravity = .resizeAspectFill
            self.configurePreviewLayer(for: .portrait)
            if let previewLayer = self.previewLayer {
                self.delegate?.didSetupPreviewLayer(_previewLayer: previewLayer)
            }
        }
    }
    
    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func startRecording() {
        guard isSessionReady else {
            print("⚠️ Capture session is not ready yet.")
            return
        }
        
        isStoppingRecording = false
        let outputFilePath = getVideoFilePath(prefix: "Lazulite", folderName: "RecordedVideos")
        print("Starting Video Record at file path: \(outputFilePath)")
        
        guard let connection = videoOutput.connection(with: .video), connection.isActive else {
            print("⚠️ Video connection is NOT active, cannot start recording!")
            return
        }
        
        DispatchQueue.main.async {
            if let connection = self.videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        print("✅ Video connection is active, starting recording...")
        videoOutput.startRecording(to: outputFilePath, recordingDelegate: self)
        print("Video Recording Started: \(videoOutput.isRecording)")
        
        // Automatically stop after 10 seconds
        
        if let floatValue = Float(UserDefaults.standard.string(forKey: "TotalTimer") ?? "10") {
            Timer.scheduledTimer(timeInterval: TimeInterval(floatValue), target: self, selector: #selector(stopRecord), userInfo: nil, repeats: false)
        } else {
            Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(stopRecord), userInfo: nil, repeats: false)
        }
        
    }
    
    @objc func stopRecord() {
        stopRecording()
    }
    
    func stopRecording() {
        print("Video Output is Recording: \(videoOutput.isRecording) \n Is Stopped Recording: \(isStoppingRecording)")
        guard videoOutput.isRecording, !isStoppingRecording else { return }
        
        isStoppingRecording = true
        print("Stopping video record")
        videoOutput.stopRecording()
        
        // Stop the session after recording is finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !self.videoOutput.isRecording {
                print("Stopping session...")
                self.captureSession.stopRunning()
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let err = error {
            print("Recording error: \(err.localizedDescription)")
            return
        } else {
            print("Recording Finished")
            
            self.delegate?.didFinishRecording(url: outputFileURL)
        }
    }
    
    private func getVideoFilePath(prefix: String,folderName: String) -> URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appVideosDirectory = documentDirectory.appendingPathComponent(folderName)
        if !fileManager.fileExists(atPath: appVideosDirectory.path) {
            do {
                try fileManager.createDirectory(at: appVideosDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating RecordedVideos Directory: \(error.localizedDescription)")
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSSS"
        let timeStamp = formatter.string(from: Date())
        
        let videoFileName = "\(prefix)_\(timeStamp).mov"
        return appVideosDirectory.appendingPathComponent(videoFileName)
    }
    
    func configurePreviewLayer(for orientation: UIDeviceOrientation) {
        guard let previewLayer = self.previewLayer else { return }
        
        switch orientation {
        case .portrait:
            print("Orientaion is portrait")
            previewLayer.connection?.videoOrientation = .portrait
        case .landscapeLeft:
            print("Orientaion is Landscape Left")
            previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            print("Orientaion is Landscape Right")
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            print("Orientaion is Portrait Upsdide Down")
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        default:
            break
        }
    }
}
