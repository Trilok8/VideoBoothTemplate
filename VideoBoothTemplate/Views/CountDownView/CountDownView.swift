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
    }
    
    private func loadNib() {
        guard let view = Bundle.main.loadNibNamed("CountDownView", owner: self, options: nil)?.first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
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
        print(images.count)
        if images.isEmpty { return }
        imgCountDown.animationImages = images
        imgCountDown.animationDuration = 3
        imgCountDown.animationRepeatCount = 1
        imgCountDown.startAnimating()
    }

}
