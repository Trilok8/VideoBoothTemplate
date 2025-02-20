//
//  RegistrationView.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 20/02/2025.
//

import UIKit

protocol RegistrationViewDelegate: AnyObject {
    func didSubmitRegistration(name: String, email: String, phone: String)
}

class RegistrationView: UIView,UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    weak var delegate: RegistrationViewDelegate?

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
        setupGestureForKeyboardDismiss()
        setupTextFields()
    }
    
    private func loadNib() {
        guard let view = Bundle.main.loadNibNamed("RegistrationView", owner: self, options: nil)?.first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    // MARK: - Setup Gesture for Keyboard Dismissal
    private func setupGestureForKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        self.endEditing(true)
    }
    
    // MARK: - Setup TextFields
    private func setupTextFields() {
        nameTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
    }
    
    // MARK: - UITextFieldDelegate Method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Hide keyboard when Return key is pressed
        return true
    }
    
    @IBAction func actionSubmit(_ sender: Any) {
        let name = nameTextField.text ?? ""
        let mail = emailTextField.text ?? ""
        let phone = phoneTextField.text ?? ""
        
        delegate?.didSubmitRegistration(name: name, email: mail, phone: phone)
        dismissKeyboard()
    }
    
}
