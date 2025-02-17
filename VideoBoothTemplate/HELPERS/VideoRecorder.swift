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
}

class VideoRecorder: NSObject,AVCaptureFileOutputRecordingDelegate {
    var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: VideoRecorderDelegate?
    
    override init() {
        super.init()
        
    }
    
    private func setupCamera(){
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                captureSession.canAddInput(videoInput) else {
            print("Error: Cannot access camera")
            return
        }
        captureSession.addInput(videoInput)
        
        videoOutput = AVCaptureMovieFileOutput()
        if(captureSession.canAddOutput(videoOutput)){
            captureSession.addOutput(videoOutput)
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if(previewLayer == nil){
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
        }
        return previewLayer
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
        let outputFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("video.mov")
        videoOutput.startRecording(to: outputFilePath, recordingDelegate: self)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let error = error {
            delegate?.didFailRecording(error: error)
        } else {
            delegate?.didFinishRecording(url: outputFileURL)
        }
    }
}
