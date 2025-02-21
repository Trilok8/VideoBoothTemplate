//
//  ExtensionVideoPreviewViewController.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 21/02/2025.
//

import UIKit
import AVFoundation

extension ViewController {
    
    func addvideoPreview(fileURL: URL) {
        if videoPreview == nil {
            let newvideoPreview = VideoPreview()
//            newvideoPreview.delegate = self
            newvideoPreview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(newvideoPreview)
            
            videoPreviewCenterXConstraint = newvideoPreview.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: videoPreviewWidth) // Start off-screen
            NSLayoutConstraint.activate([
                videoPreviewCenterXConstraint!,
                newvideoPreview.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: 10),
                newvideoPreview.widthAnchor.constraint(equalToConstant: videoPreviewWidth),
                newvideoPreview.heightAnchor.constraint(equalToConstant: videoPreviewHeight)
            ])
            
            view.layoutIfNeeded() // Apply layout updates immediately
            videoPreview = newvideoPreview
            
            // Animate by changing the leading constraint
            videoPreviewCenterXConstraint?.isActive = false
            videoPreviewCenterXConstraint = newvideoPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0) // Move in from the right
            videoPreviewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: [], animations: {
                self.view.layoutIfNeeded() // Animate layout change
            })
            videoPreview?.playVideo(with: fileURL)
        }
    }
    
    /// Function to remove StartView with slide-out to the left animation
    func removevideoPreview() {
        if let existingView = videoPreview {
            videoPreviewCenterXConstraint?.isActive = false
            videoPreviewCenterXConstraint = existingView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -view.frame.width) // Move out to left
            videoPreviewCenterXConstraint?.isActive = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded() // Animate layout update
            }) { _ in
                existingView.removeFromSuperview()
                self.videoPreview = nil
            }
        }
    }
}
