//
//  VideoPreview.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 21/02/2025.
//

import UIKit
import AVFoundation

class VideoPreview: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnPause: UIButton!
    @IBOutlet weak var slider: UISlider!
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
        setupPlayerLayer()
    }
    
    private func loadFromNib() {
        let nib = UINib(nibName: "VideoPreview", bundle: Bundle.main)
        let contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        contentView.backgroundColor = .clear
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        // Now we can set up the controls after they are loaded from the XIB
        setupControls()
    }
    
    private func setupPlayerLayer() {
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer!)
    }
    
    // MARK: - Setup Controls
    private func setupControls() {
        // Setup control actions for playPauseButton, slider, and timeLabel
        btnPlay.addTarget(self, action: #selector(actionPlay), for: .touchUpInside)
        btnPause.addTarget(self, action: #selector(actionPause), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    // MARK: - Public Methods
    func playVideo(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        playerLayer?.player = player
        
        NotificationCenter.default.addObserver(self, selector: #selector(restartVideo), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        addTimeObserver()
        player?.play()
    }
    
    func stopVideo() {
        player?.pause()
        player = nil
        playerLayer?.player = nil
    }
    
    @objc private func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func actionPlay() {
        guard let player = player else { return }
        if player.timeControlStatus != .playing {
            player.play()
        }
    }
    
    @objc private func actionPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        }
    }
    
    @objc private func sliderValueChanged() {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        let newTime = CMTime(seconds: Double(slider.value) * duration, preferredTimescale: 600)
        player?.seek(to: newTime)
    }
    
    private func addTimeObserver() {
        guard let player = player else { return }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self, let duration = self.player?.currentItem?.duration.seconds, duration > 0 else { return }
            self.slider.value = Float(time.seconds / duration)
            self.updateTimeLabel(currentTime: time.seconds, duration: duration)
        }
    }
    
    private func updateTimeLabel(currentTime: Double, duration: Double) {
        let current = formatTime(seconds: currentTime)
        let total = formatTime(seconds: duration)
        timeLabel.text = "\(current) / \(total)"
    }
    
    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
