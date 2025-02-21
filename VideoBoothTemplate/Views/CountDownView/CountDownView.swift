//
//  CountDownView.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 20/02/2025.
//

import UIKit

class CountDownView: UIView {
    
    @IBOutlet weak var imgCountDown: UIImageView!
    private var images: [UIImage] = [UIImage]()
    
    private var countdownImages = ["3", "2", "1"]
    private var countdownIndex = -1
    private var countdownImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        loadNib()
        addImages()
        createImageView()
        animateImages()
    }
    
    private func loadNib() {
        guard let view = Bundle.main.loadNibNamed("CountDownView", owner: self, options: nil)?.first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    private func createImageView() {
        countdownImageView = UIImageView()
        countdownImageView.contentMode = .scaleAspectFit
        countdownImageView.alpha = 0 // Initially hidden
        countdownImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countdownImageView)
        
        // Constraints for countdownImageView (Position at the bottom of the superview)
        NSLayoutConstraint.activate([
            countdownImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            countdownImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -100), // Adjust the '20' to control the distance from the bottom
            countdownImageView.widthAnchor.constraint(equalToConstant: 100),
            countdownImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - Start Countdown Animation
    func startCountdown(completion: @escaping () -> Void) {
        countdownIndex = -1
        setupInitialImage()
        animateCountdown(completion: completion)
    }
    
    private func setupInitialImage() {
        if let path = Bundle.main.path(forResource: countdownImages[countdownIndex + 1], ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            countdownImageView.image = image
        }
        
        // Initially set the image alpha to 1 (visible)
        countdownImageView.alpha = 1
    }
    
    private func animateCountdown(completion: @escaping () -> Void) {
        guard countdownIndex < countdownImages.count else {
            // Animation completed, either stop or repeat
            completion() // Finish when all images are shown
            return
        }
        
        // Fade out the current image
        UIView.animate(withDuration: 0, animations: {
            self.countdownImageView.alpha = 0
        }) { _ in
            // Move to the next image
            self.countdownIndex += 1
            
            // Reset countdownIndex if it exceeds bounds (loop or stop)
            if self.countdownIndex < 3 {
                // Update the image
                print("Count Down Index = \(self.countdownIndex)")
                if let path = Bundle.main.path(forResource: self.countdownImages[self.countdownIndex], ofType: "png"),
                   let image = UIImage(contentsOfFile: path) {
                    self.countdownImageView.image = image
                }
                
                // Fade in the new image
                UIView.animate(withDuration: 0.6, animations: {
                    self.countdownImageView.alpha = 1
                }) { _ in
                    // Wait for 1 second before transitioning to the next image
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.animateCountdown(completion: completion)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.animateCountdown(completion: completion)
                }
            }
        }
    }
    
    //MARK: - Play PNG Sequence
    private func addImages(){
        for i in 0...90 {
            let number = String(format: "%02d", i)
            if let path = Bundle.main.path(forResource: "Step back\(number)", ofType: ".png"){
                if let image = UIImage(contentsOfFile: path){
                    images.append(image)
                }
            }
        }
    }
    
    func animateImages(){
        if images.isEmpty { return }
        imgCountDown.animationImages = images
        imgCountDown.animationDuration = 3
        imgCountDown.animationRepeatCount = .max
        imgCountDown.startAnimating()
    }
    
}
