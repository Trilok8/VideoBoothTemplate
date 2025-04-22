//
//  ViewController.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 17/02/2025.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController,VideoRecorderDelegate,QRViewDelegate {
    
    func btnHomeClicked() {
        restartApplication()
    }
    
    func restartApplication() {
        guard let window = UIApplication.shared.windows.first else { return }
        let rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        // Optional: Add a fade transition for a smoother restart effect
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
    
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnStopRecord: UIButton!
    @IBOutlet weak var recordingView: UIView!
    @IBOutlet weak var bgVideoPlayerView: UIView!
    @IBOutlet weak var recBG: UIImageView!
    @IBOutlet weak var imgLive: UIImageView!
    @IBOutlet weak var btnRetake: UIButton!
    @IBOutlet weak var btnUpload: UIButton!
    @IBOutlet weak var imgLogo: UIImageView!
    
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var videoRecorder: VideoRecorder!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let recordButton = UIButton()
    let stopBUTTON = UIButton()
    
    var videoPreview: VideoPreview?
    var videoPreviewCenterXConstraint: NSLayoutConstraint?
    var videoPreviewWidth: CGFloat = 700
    var videoPreviewHeight: CGFloat = 950
    
    var qrView: QRView?
    var qrViewCenterXConstraint: NSLayoutConstraint?
    var qrViewWidth: CGFloat = 834
    var qrViewHeight: CGFloat = 1194
    
    private var countDownView: CountDownView?
    private var countDownCenterXConstraint: NSLayoutConstraint?
    private var countDownViewWidth: CGFloat = 834
    private var countDownViewHeight: CGFloat = 1194
    
    private var finalVideoURL: URL?
    
    private var startTime: Double = Double()
    private var stopTime: Double = Double()
    //MARK: - VideoRecord Delegate methods
    func didFinishRecording(url: URL?) {
        if let videoURL = url {
            print(videoURL.absoluteString)
            
            let videoEditor = VideoEditor()
            let outputURL = videoEditor.getVideoFilePath(prefix: "Lazulite")

            // ✅ Set slow motion to start at 3 seconds and last for 5 seconds
            if let floatValue = Double(UserDefaults.standard.string(forKey: "SlowStart") ?? "1"),let floatValue2 = Double(UserDefaults.standard.string(forKey: "SlowSeconds") ?? "1") {
                startTime = floatValue
                stopTime = floatValue2
            } else {
                startTime = 1
                stopTime = 3
            }
            let slowMotionStart = CMTime(seconds: startTime, preferredTimescale: 600)
            let slowMotionDuration = CMTime(seconds: stopTime, preferredTimescale: 600)

            videoEditor.applySlowMotionEffect(to: videoURL, slowMotionStart: slowMotionStart, slowMotionDuration: slowMotionDuration, outputURL: outputURL) { success, editedVideoURL in
                if success, let url = editedVideoURL {
                    print("🎥 Slow-motion video available at: \(url)")
                    self.finalVideoURL = url
                    self.addvideoPreview(fileURL: url)
                    self.recordingView.isHidden = true
                    self.recBG.isHidden = true
                    self.imgLive.isHidden = true
                    
                    self.btnRetake.isHidden = false
                    self.btnUpload.isHidden = false
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
            self.addShadow(to: self.recordingView)
            
            self.recBG.isHidden = false
            self.imgLive.isHidden = false
            
            self.videoRecorder.startRecording()
        }
    }
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        recBG.isHidden = true
        imgLive.isHidden = true
        
        btnRetake.isHidden = true
        btnUpload.isHidden = true
        
        btnRecord.isHidden = true
        btnStopRecord.isHidden = true
        
        setupVideoRecorder()
        playVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    
    @IBAction func actionRetake(_ sender: Any) {
        removevideoPreview()
        addCountDownView()
        recordingView.isHidden = true
        recBG.isHidden = true
        imgLive.isHidden = true
        imgLogo.isHidden = true
        btnRetake.isHidden = true
        btnUpload.isHidden = true
    }
    
    @IBAction func actionGenerateQR(_ sender: Any) {
        if let fileURL = finalVideoURL{
            print("File url not nil")
            uploadVideo(fileURL: fileURL) { result in
                switch result {
                case .success(let fileName):
                    self.removevideoPreview()
                    self.addQRView(fileName: fileName)
                case .failure(let error):
                    print("Something went wrong")
                }
            }
        }
    }
    
    func uploadVideo(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let file: Data = try Data(contentsOf: fileURL)
            
            //https://lazulite.online/routes/UAEU/upload-video
            //
            if let url = URL(string: "https://lazulite.online/routes/Lazulite/upload-video"){
                let headers = [
                    "Content-type": "multipart/form-data"
                ]
                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(file, withName: "video",fileName: "video.mov")
                }, to: url).responseString { response in
                    switch response.result {
                    case .success(let fileName):
                        completion(.success(fileName))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
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
    
    //MARK: - Background Video Methods
    func playVideo() {
        guard let filePath = Bundle.main.path(forResource: "UAEU Idle Screen", ofType: "mp4") else {
            print("Video file not found")
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let playerItem = AVPlayerItem(url: fileURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Create a player layer and add it to the view
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bgVideoPlayerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill // or .resizeAspect for different behaviors
        bgVideoPlayerView.layer.addSublayer(playerLayer!)
        
        // Play the video
        player?.play()
        
        // Loop the video
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @objc func videoDidEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }
    
    //MARK: - Add Shadow
    func addShadow(to view: UIView) {
        // Set the shadow color (Black in this case)
        view.layer.shadowColor = UIColor.black.cgColor
        
        // Set the shadow opacity (0 is transparent, 1 is opaque)
        view.layer.shadowOpacity = 0.7
        
        // Set the shadow offset (X, Y)
        view.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        // Set the shadow radius (controls the blur of the shadow)
        view.layer.shadowRadius = 10
        
        // Optional: Add corner radius (to round the corners of the UIView)
        view.layer.cornerRadius = 25
        previewLayer.cornerRadius = 25
    }
    
    //MARK: - Status Bar & Home Indicator Methods
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - CountDownView Methods
    func addCountDownView() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.sendCommand(command: UserDefaults.standard.string(forKey: "StartCommand") ?? "")
        if countDownView == nil {
            let newCountDownView = CountDownView()
            //newCountDownView.delegate = self
            newCountDownView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newCountDownView)
            
            countDownCenterXConstraint = newCountDownView.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: countDownViewWidth) // Start off-screen
            NSLayoutConstraint.activate([
                countDownCenterXConstraint!,
                newCountDownView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                newCountDownView.widthAnchor.constraint(equalToConstant: countDownViewWidth),
                newCountDownView.heightAnchor.constraint(equalToConstant: countDownViewHeight)
            ])
            
            view.layoutIfNeeded() // Apply layout updates immediately
            countDownView = newCountDownView
            
            // Animate by changing the leading constraint
            countDownCenterXConstraint?.isActive = false
            countDownCenterXConstraint = newCountDownView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0) // Move in from the right
            countDownCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [], animations: {
                self.view.layoutIfNeeded() // Animate layout change
            }) { isCompleted in
                if(isCompleted){
                    if let doubleValue = Double(UserDefaults.standard.string(forKey: "CountDown") ?? "3"){
                        Timer.scheduledTimer(timeInterval: doubleValue, target: self, selector: #selector(self.startCountDown), userInfo: nil, repeats: false)
                    }
                }
            }
            
            
        }
    }
    
    @objc func startCountDown(){
        self.countDownView?.startCountdown { [weak self] in
            print("Countdown finished!")
            guard let self = self else { return }
            
            countDownView?.removeFromSuperview()
            self.countDownView = nil
            imgLogo.isHidden = true
            recordingView.isHidden = false
            recBG.isHidden = false
            imgLive.isHidden = false
            videoRecorder.cameraSetup()
        }
    }
    
    /// Function to remove StartView with slide-out to the left animation
    func removeCountDownView() {
        if let existingView = countDownView {
            countDownCenterXConstraint?.isActive = false
            countDownCenterXConstraint = existingView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -view.frame.width) // Move out to left
            countDownCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded() // Animate layout update
            }) { _ in
                existingView.removeFromSuperview()
                self.countDownView = nil
            }
        }
    }
    
    //MARK: - QR View
    func addQRView(fileName: String) {
        
        btnRetake.isHidden = true
        btnUpload.isHidden = true
        imgLogo.isHidden = true
        if qrView == nil {
            let newQRView = QRView()
            newQRView.delegate = self
            newQRView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newQRView)
            
            qrViewCenterXConstraint = newQRView.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: qrViewWidth) // Start off-screen
            NSLayoutConstraint.activate([
                qrViewCenterXConstraint!,
                newQRView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: 10),
                newQRView.widthAnchor.constraint(equalToConstant: qrViewWidth),
                newQRView.heightAnchor.constraint(equalToConstant: qrViewHeight)
            ])
            
            view.layoutIfNeeded() // Apply layout updates immediately
            qrView = newQRView
            
            // Animate by changing the leading constraint
            qrViewCenterXConstraint?.isActive = false
            qrViewCenterXConstraint = newQRView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0) // Move in from the right
            qrViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [], animations: {
                self.view.layoutIfNeeded() // Animate layout change
            })
            
            qrView?.setQRCode(urlString: "https://lazulite.online/routes/Lazulite/DownloadVideo?filename=\(fileName)")
        }
    }
    
    /// Function to remove StartView with slide-out to the left animation
    func removeQRView() {
        if let existingView = qrView {
            qrViewCenterXConstraint?.isActive = false
            qrViewCenterXConstraint = existingView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -view.frame.width) // Move out to left
            qrViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded() // Animate layout update
            }) { _ in
                existingView.removeFromSuperview()
                self.qrView = nil
            }
        }
    }
    
}

