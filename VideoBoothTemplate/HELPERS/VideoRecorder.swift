//
//  VideoRecorder.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 17/02/2025.
//

import AVFoundation

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
    
    weak var delegate: VideoRecorderDelegate?
    
    override init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    private func setupCamera(){
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Error: Cannot access camera")
            return
        }
        
        videoDevice = device
        videoInput = input
        
        if(captureSession.canAddInput(videoInput)){
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
        if(captureSession.canAddOutput(videoOutput)){
            captureSession.addOutput(videoOutput)
        }
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = self.previewLayer {
                self.delegate?.didSetupPreviewLayer(_previewLayer: previewLayer)
            }
        }
        
    }
    
    func startSession(){
        if(!captureSession.isRunning){
            captureSession.startRunning()
        }
    }
    
    func stopSession(){
        if(captureSession.isRunning){
            captureSession.stopRunning()
        }
    }
    
    func startRecording(){
        let outputFilePath = getVideoFilePath(prefix: "Lazulite")
        videoOutput.startRecording(to: outputFilePath, recordingDelegate: self)
    }
    
    func stopRecording(){
        videoOutput.stopRecording()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let err = error {
            print("Recording error: \(err.localizedDescription)")
            return
        }
        delegate?.didFinishRecording(url: outputFileURL)
    }
    
    private func getVideoFilePath(prefix: String) -> URL{
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appVideosDirectory = documentDirectory.appendingPathComponent("RecordedVideos")
        
        if !fileManager.fileExists(atPath: appVideosDirectory.path){
            do{
                try fileManager.createDirectory(at: appVideosDirectory, withIntermediateDirectories: true,attributes: nil)
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
}
