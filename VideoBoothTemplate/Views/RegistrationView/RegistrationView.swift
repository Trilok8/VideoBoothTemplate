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
let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

class RegistrationView: UIView,UITextFieldDelegate {
    
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    weak var delegate: RegistrationViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        lblError.text = ""
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
        if(name.count > 3 && isValidEmail(mail) && phone.count >= 9) {
            writeToCSV(fileName: "UserData.csv", data: [name,mail,phone])
        } else {
            if(name.count < 3){
                lblError.text = "Name should be atleast 3 characters"
            } else if(isValidEmail(mail)){
                lblError.text = "Mail example abc@gmail.com"
            } else if(phone.count < 9) {
                lblError.text = "Phone Number should have atleast 9 digits"
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    func writeToCSV(fileName: String, data: [String]) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        let csvLine = data.joined(separator: ",") + "\n"
        
        if fileManager.fileExists(atPath: fileURL.path) {
            // Append new data
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let data = csvLine.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
                delegate?.didSubmitRegistration(name: data[0], email: data[1], phone: data[2])
                dismissKeyboard()
            }
        } else {
            // Create new file and write header + first row
            do {
                try csvLine.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error writing CSV: \(error.localizedDescription)")
            }
        }
        
        print("CSV updated at: \(fileURL.path)")
    }
    
}
