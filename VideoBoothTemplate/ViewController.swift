//
//  ViewController.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 17/02/2025.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,VideoRecorderDelegate {
    
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnStopRecord: UIButton!
    @IBOutlet weak var recordingView: UIView!
    
    func didFinishRecording(url: URL?) {
        if let videoURL = url {
            print(videoURL.absoluteString)
            
            let videoEditor = VideoEditor()
            let outputURL = videoEditor.getVideoFilePath(prefix: "Lazulite")

            // ✅ Set slow motion to start at 3 seconds and last for 5 seconds
            let slowMotionStart = CMTime(seconds: 3, preferredTimescale: 600)
            let slowMotionDuration = CMTime(seconds: 5, preferredTimescale: 600)

            videoEditor.applySlowMotionEffect(to: videoURL, slowMotionStart: slowMotionStart, slowMotionDuration: slowMotionDuration, outputURL: outputURL) { success, editedVideoURL in
                if success, let url = editedVideoURL {
                    print("🎥 Slow-motion video available at: \(url)")
                } else {
                    print("❌ Failed to apply slow motion effect")
                }
            }
        }
    }
    
    func didFailRecording(error: (any Error)?) {
        if let err = error {
            print(err.localizedDescription)
        }
    }
    
    func didSetupPreviewLayer(_previewLayer: AVCaptureVideoPreviewLayer) {
        DispatchQueue.main.async {
            self.previewLayer = _previewLayer
            self.previewLayer.frame = self.recordingView.bounds
            self.recordingView.layer.addSublayer(self.previewLayer)
            self.videoRecorder.startSession()
        }
    }

    var videoRecorder: VideoRecorder!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let recordButton = UIButton()
    let stopBUTTON = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showStartRecordButton()
        setupVideoRecorder()
    }

    func setupVideoRecorder(){
        videoRecorder = VideoRecorder()
        videoRecorder.delegate = self
    }
    
    @IBAction func startRecord(_ sender: Any) {
        showStopRecordButton()
        videoRecorder.startRecording()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        showStartRecordButton()
        videoRecorder.stopRecording()
    }
    
    
    func showStartRecordButton(){
        btnRecord.isHidden = false
        btnStopRecord.isHidden = true
    }
    
    func showStopRecordButton(){
        btnRecord.isHidden = true
        btnStopRecord.isHidden = false
    }

}

