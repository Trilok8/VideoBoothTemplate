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
    private var videoInput: AVCaptureDeviceInput!
    private var isSlowMotion = false
    private var slowMotionTimer: Timer?
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
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Error: Cannot access camera")
            return
        }
        
        videoDevice = device
        videoInput = input
        
        if(captureSession.canAddInput(videoInput)){
            captureSession.addInput(videoInput)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if(captureSession.canAddOutput(videoOutput)){
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
        
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
        startAutoSlowMotionToggle(interval: 5)
    }
    
    func stopRecording(){
        videoOutput.stopRecording()
        stopSlowMotionTimer()
    }
    
    private func startAutoSlowMotionToggle(interval: TimeInterval){
        slowMotionTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(triggerSlowMotionAuto), userInfo: nil, repeats: true)
    }
    
    private func stopSlowMotionTimer(){
        slowMotionTimer?.invalidate()
        slowMotionTimer = nil
    }
    
    @objc func triggerSlowMotionAuto(){
        toggleSlowMotion()
    }
    
    func toggleSlowMotion(){
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do{
                try self.videoDevice.lockForConfiguration()
                print("Slow Motion Status = \(self.isSlowMotion)")
                if(self.isSlowMotion){
                    self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                    self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
                    print("Now recording video in 30 FPS")
                } else {
                    if let slowMotionFormat = self.videoDevice.formats
                        .filter({ $0.videoSupportedFrameRateRanges.contains{ $0.maxFrameRate >= 240} })
                        .last{
                        self.videoDevice.activeFormat = slowMotionFormat
                        self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 240)
                        self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 240)
                        print("Now recording in slow motion")
                    } else {
                        print("Slow motion is not supported by the camera")
                    }
                }
                self.videoDevice.unlockForConfiguration()
                self.isSlowMotion.toggle()
            } catch {
                print("Error configuration frame rate = \(error.localizedDescription)")
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let error = error {
            delegate?.didFailRecording(error: error)
        } else {
            delegate?.didFinishRecording(url: outputFileURL)
        }
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
