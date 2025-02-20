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
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        addStartView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds // Adjust size when rotating
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
        if countDownView == nil {
            let newCountDownView = CountDownView()
            //newCountDownView.delegate = self
            newCountDownView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newCountDownView)
            
            countDownCenterXConstraint = newCountDownView.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: registrationWidth) // Start off-screen
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
                    print("CountDown View slide in status = \(isCompleted)")
                    self.countDownView?.animateImages()
                }
            }
            
            
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
    
    //MARK: - Status Bar & Home Indicator Methods
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
