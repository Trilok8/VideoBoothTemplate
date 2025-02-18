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
    private var videoFiles: [URL] = []
    
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
        videoFiles.removeAll()
        let outputFilePath = getVideoFilePath(prefix: "Lazulite")
        videoOutput.startRecording(to: outputFilePath, recordingDelegate: self)
        startAutoSlowMotionToggle(interval: 5)
    }
    
    func stopRecording(){
        videoOutput.stopRecording()
        stopSlowMotionTimer()
    }
    
    private func startNewRecording(){
        let videoURL = getVideoFilePath(prefix: "Lazulite")
        videoFiles.append(videoURL)
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
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
            self.videoOutput.stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isSlowMotion.toggle()
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
                            print("Now recording video in  240 FPS")
                        } else {
                            print("Slow motion is not supported by the camera")
                        }
                    }
                    self.videoDevice.unlockForConfiguration()
                    
                } catch {
                    print("Error configuration frame rate = \(error.localizedDescription)")
                }
                self.startNewRecording()
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let err = error {
            print("Recording error: \(err.localizedDescription)")
            return
        }
        if videoFiles.count > 1 {
            mergeVideos()
        } else {
            delegate?.didFinishRecording(url: outputFileURL)
        }
    }
    
    private func mergeVideos(){
        let composition = AVMutableComposition()
        
        Task {
            for videoURL in videoFiles {
                let asset = AVURLAsset(url: videoURL)
                if let duration = await getAssetDuration(url: videoURL){
                    do {
                        let tracks = try await asset.loadTracks(withMediaType: .video)
                        
                        guard let videoTrack = tracks.first else { return }
                        
                        let timeRange = CMTimeRange(start: .zero, duration: duration)
                        
                        if let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid){
                            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: composition.duration)
                        }
                    } catch {
                        print("Error loading tracks: \(error.localizedDescription)")
                    }
                } else {
                    print("Failed to get duration for asset: \(videoURL)")
                }
            }
        }
        
//        let exportSelection = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
//        let outputURL = getVideoFinalFilePath(prefix: "Lazulite")
//        exportSelection?.outputURL = outputURL
//        exportSelection?.outputFileType = .mov
//        exportSelection?.exportAsynchronously {
//            DispatchQueue.main.async {
//                self.delegate?.didFinishRecording(url: outputURL)
//            }
//        }
    }
    
    private func getAssetDuration(url: URL) async -> CMTime? {
        let asset = AVURLAsset(url: url)
        do {
            let duration: CMTime = try await asset.load(.duration)
            return duration
        } catch {
            print("Failed to load asset duration: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getVideoFinalFilePath(prefix: String) -> URL{
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appVideosDirectory = documentDirectory.appendingPathComponent("FinalVideos")
        
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
