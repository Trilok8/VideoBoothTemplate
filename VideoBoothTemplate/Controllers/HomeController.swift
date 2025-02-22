//
//  HomeController.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 20/02/2025.
//

import UIKit
import AVFoundation

class HomeController: UIViewController,StartViewDelegate,RegistrationViewDelegate {
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    private var startView: StartView?
    private var startViewCenterXConstraint: NSLayoutConstraint?
    private var startViewWidth:CGFloat = 603
    private var startViewHeight:CGFloat = 738
    
    private var registrationView: RegistrationView?
    private var registrationViewCenterXConstraint: NSLayoutConstraint?
    private var registrationWidth: CGFloat = 834
    private var registrationViewHeight: CGFloat = 1194
    
    private var countDownView: CountDownView?
    private var countDownCenterXConstraint: NSLayoutConstraint?
    private var countDownViewWidth: CGFloat = 834
    private var countDownViewHeight: CGFloat = 1194
    
    private var count: Int = 0
    var resetTimer: Timer?
    
    @IBOutlet weak var btnConfig: UIButton!
    @IBOutlet weak var configView: UIView!
    
    @IBOutlet weak var fldDeviceName: UITextField!
    @IBOutlet weak var fldTotalTimer: UITextField!
    @IBOutlet weak var fldCountDownTimer: UITextField!
    @IBOutlet weak var fldSlowStart: UITextField!
    @IBOutlet weak var fldSlowSeconds: UITextField!
    @IBOutlet weak var fldArmCommand: UITextField!
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Width = \(view.bounds.width), Height = \(view.bounds.height)")
        playVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configView.isHidden = true
        addStartView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds // Adjust size when rotating
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @IBAction func showConfig(_ sender: Any) {
        if(count < 3){
            resetTimer?.invalidate()
            count = count + 1
            resetTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(resetConfig), userInfo: nil, repeats: false)
        } else {
            count = 0
            configView.isHidden = false
            view.bringSubviewToFront(configView)
            fldDeviceName.text = UserDefaults.standard.string(forKey: "DeviceName")
            fldTotalTimer.text = UserDefaults.standard.string(forKey: "TotalTimer")
            fldCountDownTimer.text = UserDefaults.standard.string(forKey: "CountDown")
            fldSlowStart.text = UserDefaults.standard.string(forKey: "SlowStart")
            fldSlowSeconds.text = UserDefaults.standard.string(forKey: "SlowSeconds")
            fldArmCommand.text = UserDefaults.standard.string(forKey: "StartCommand")
        }
    }
    
    @objc func resetConfig(){
        count = 0
    }
    
    @IBAction func actionSaveConfig(_ sender: Any) {
        UserDefaults.standard.set(fldDeviceName.text, forKey: "DeviceName")
        UserDefaults.standard.set(fldTotalTimer.text, forKey: "TotalTimer")
        UserDefaults.standard.set(fldCountDownTimer.text, forKey: "CountDown")
        UserDefaults.standard.set(fldSlowStart.text, forKey: "SlowStart")
        UserDefaults.standard.set(fldSlowSeconds.text, forKey: "SlowSeconds")
        UserDefaults.standard.set(fldArmCommand.text, forKey: "StartCommand")
    }
    
    @IBAction func actionCloseConfig(_ sender: Any) {
        configView.isHidden = true
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
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill // or .resizeAspect for different behaviors
        view.layer.addSublayer(playerLayer!)
        
        // Play the video
        player?.play()
        
        // Loop the video
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @objc func videoDidEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }
    
    //MARK: - StartView Methods
    func addStartView() {
        if startView == nil {
            let newStartView = StartView()
            newStartView.delegate = self
            newStartView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newStartView)
            view.bringSubviewToFront(btnConfig)
            startViewCenterXConstraint = newStartView.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: startViewWidth) // Start off-screen
            NSLayoutConstraint.activate([
                startViewCenterXConstraint!,
                newStartView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                newStartView.widthAnchor.constraint(equalToConstant: startViewWidth),
                newStartView.heightAnchor.constraint(equalToConstant: startViewHeight)
            ])
            
            view.layoutIfNeeded() // Apply layout updates immediately
            startView = newStartView
            
            // Animate by changing the leading constraint
            startViewCenterXConstraint?.isActive = false
            startViewCenterXConstraint = newStartView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0) // Move in from the right
            startViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [], animations: {
                self.view.layoutIfNeeded() // Animate layout change
            })
        }
    }
    
    /// Function to remove StartView with slide-out to the left animation
    func removeStartView() {
        if let existingView = startView {
            startViewCenterXConstraint?.isActive = false
            startViewCenterXConstraint = existingView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -view.frame.width) // Move out to left
            startViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded() // Animate layout update
            }) { _ in
                existingView.removeFromSuperview()
                self.startView = nil
            }
        }
    }
    
    func startButtonClicked() {
        removeStartView()
        addRegistrationView()
    }
    
    //MARK: - RegistrationView Methods
    func addRegistrationView() {
        if registrationView == nil {
            let newRegistrationView = RegistrationView()
            newRegistrationView.delegate = self
            newRegistrationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newRegistrationView)
            
            registrationViewCenterXConstraint = newRegistrationView.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: registrationWidth) // Start off-screen
            NSLayoutConstraint.activate([
                registrationViewCenterXConstraint!,
                newRegistrationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                newRegistrationView.widthAnchor.constraint(equalToConstant: registrationWidth),
                newRegistrationView.heightAnchor.constraint(equalToConstant: registrationViewHeight)
            ])
            
            view.layoutIfNeeded() // Apply layout updates immediately
            registrationView = newRegistrationView
            
            // Animate by changing the leading constraint
            registrationViewCenterXConstraint?.isActive = false
            registrationViewCenterXConstraint = newRegistrationView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0) // Move in from the right
            registrationViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [], animations: {
                self.view.layoutIfNeeded() // Animate layout change
            })
        }
    }
    
    /// Function to remove StartView with slide-out to the left animation
    func removeRegistrationView() {
        if let existingView = registrationView {
            registrationViewCenterXConstraint?.isActive = false
            registrationViewCenterXConstraint = existingView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -view.frame.width) // Move out to left
            registrationViewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded() // Animate layout update
            }) { _ in
                existingView.removeFromSuperview()
                self.registrationView = nil
            }
        }
    }
    
    func didSubmitRegistration(name: String, email: String, phone: String) {
        print("Name = \(name) Mail = \(email) Phone = \(phone)")
        removeRegistrationView()
        addCountDownView()
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
            self.presentRecordController()
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
                self.presentRecordController()
            }
        }
    }
    
    func presentRecordController(){
        let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    
    //MARK: - Status Bar & Home Indicator Methods
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
