//
//  QRView.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 21/02/2025.
//

import UIKit

protocol QRViewDelegate: AnyObject {
    func btnHomeClicked()
}

class QRView: UIView {
    
    @IBOutlet weak var imgViewQR: UIImageView!
    var delegate: QRViewDelegate?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
    }
    
    private func loadFromNib() {
        let nib = UINib(nibName: "QRView", bundle: Bundle.main)
        let contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    // Function to update the QR image
    func setQRCode(urlString: String) {
        if let qrImage = generateQRCode(from: urlString){
            imgViewQR.image = qrImage
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) // Scale up
        return UIImage(ciImage: transformedImage)
    }
    
    @IBAction func actionHome(_ sender: Any) {
        delegate?.btnHomeClicked()
    }
    
}
