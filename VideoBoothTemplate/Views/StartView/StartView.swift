//
//  StartView.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 20/02/2025.
//

import UIKit

protocol StartViewDelegate: AnyObject {
    func startButtonClicked()
}

class StartView: UIView {
    
    weak var delegate: StartViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        guard let view = Bundle.main.loadNibNamed("StartView", owner: self, options: nil)?.first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.startButtonClicked()
    }
    
    
}
