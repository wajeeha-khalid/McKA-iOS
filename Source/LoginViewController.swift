//
//  LoginViewController.swift
//  edX
//
//  Created by Salman Jamil on 7/31/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import QuartzCore

@objc protocol LoginViewControllerDelegate : class {
    func loginViewControllerDidLogin(_ vc: LoginViewController)
}

enum MessageType {
    case error
    case info
    case success
}

struct Message {
    let title: String?
    let message: String?
    let type: MessageType
}

protocol LoginView {
    func present(message: Message)
    func showActivityIndicator()
    func hideActivityIndicator()
    func loginSuccessfull()
}

protocol Authenticator {
    func resetPassword(withEmailID emailID: String) -> edXCore.Stream<()>
    func authenticateUserWith(username: String, password: String) -> edXCore.Stream<()>
}

@objc protocol LoginPresenterDelegate: class {
    func loginPresenterDidLogin(_ presenter: LoginPresenter)
}

final class RemoteAuthenticator: Authenticator {
    
    static let shared = RemoteAuthenticator()
    
    //This is marked as private so that clients can't instantiate
    //the instance of this class directly
    private init() {
        
    }
    
    func resetPassword(withEmailID emailID: String) -> edXCore.Stream<()> {
        let stream: BackedStream<()> = BackedStream()
        OEXAuthentication.resetPassword(withEmailId: emailID) { (data, response, error) in
            if error == nil && response?.statusCode == 200 {
                stream.backWithStream(Stream(value: ()))
            } else if let statusCode = response?.statusCode, (400..<500).contains(statusCode) {
                let dict = data.flatMap {
                    (try? JSONSerialization.jsonObject(with: $0, options: [])).flatMap {$0 as? [String : Any]}
                }
                let responseStr = (dict?["email"] as? [String])?.first
                let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey : responseStr ?? ""])
                stream.backWithStream(Stream(error: error))
            } else if let statusCode = response?.statusCode, statusCode >= 500 {
                let responseStr = data.flatMap {
                    String(data: $0, encoding: .utf8)
                }
                let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey : responseStr ?? ""])
                stream.backWithStream(Stream(error: error))
            } else  {
                let error = NSError(domain: "", code: response?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey : error?.localizedDescription ?? ""])
                stream.backWithStream(Stream(error: error))
            }
        }
        return stream
    }
    
    func authenticateUserWith(username: String, password: String) -> edXCore.Stream<()> {
        let stream: BackedStream<()> = BackedStream()
        
        OEXAuthentication.requestToken(withUser: username, password: password) { (data, response, error) in
            if error == nil, response?.statusCode == 200 {
                stream.backWithStream(Stream(value: ()))
            } else if let statusCode = response?.statusCode, (400..<500).contains(statusCode) {
                let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey : Strings.invalidUsernamePassword])
                stream.backWithStream(Stream(error: error))
            } else if let description = error?.localizedDescription {
                let error = NSError(domain: "", code: response?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey : description])
                stream.backWithStream(Stream(error: error))
            }
        }
        
        return stream
    }
}

//This class implements the business logic related to login
public class LoginPresenter: NSObject {
    
    let authenticator: Authenticator
    let view: LoginView
    let reachability: Reachability
    weak var delegate: LoginPresenterDelegate?
    
    init(authenticator: Authenticator, view: LoginView, reachability: Reachability) {
        self.reachability = reachability
        self.authenticator = authenticator
        self.view = view
    }
    
    func loginWith(username: String, password: String) {
        guard reachability.isReachable() else {
            let message = Message(title: Strings.networkNotAvailableTitle, message: Strings.networkNotAvailableMessage, type: .error)
            view.present(message: message)
            return
        }
        
        view.showActivityIndicator()
        authenticator.authenticateUserWith(username: username, password: password).listen(self) { result in
            self.view.hideActivityIndicator()
            switch result {
            case .success:
                self.delegate?.loginPresenterDidLogin(self)
                UserDefaults.standard.set(true, forKey: FIRST_TIME_USER_KEY)
                UserDefaults.standard.set(false, forKey: FTUE)
                OEXInterface.setCCSelectedLanguage("")
                UserDefaults.standard.set(username, forKey: "USERNAME")
                OEXAnalytics.shared().trackUserLogin("Password")
                self.view.loginSuccessfull()
            case .failure(let error):
                let message = Message(title: nil, message: error.localizedDescription, type: .error)
                self.view.present(message: message)
            }
        }
    }
    
    func forgotPassword(withEmailID emailID: String) {
        guard reachability.isReachable() else {
            let message = Message(title: Strings.networkNotAvailableTitle, message: Strings.networkNotAvailableMessage, type: .error)
            view.present(message: message)
            return
        }
        
        if emailID.oex_isValidEmailAddress() == false {
            let message = Message(title: Strings.floatingErrorTitle, message: Strings.invalidEmailMessage, type: .error)
            view.present(message: message)
            return
        }
        
        view.showActivityIndicator()
        
        authenticator.resetPassword(withEmailID: emailID).listen(self) { result in
            self.view.hideActivityIndicator()
            switch result {
            case .success:
                let message = Message(title: Strings.resetPasswordConfirmationTitle, message: Strings.resetPasswordConfirmationMessage, type: .success)
                self.view.present(message: message)
            case .failure(let error):
                let message = Message(title: Strings.floatingErrorTitle, message: error.localizedDescription, type: .error)
                self.view.present(message: message)
            }
        }
    }
}

class LoginViewController: UIViewController {

    //we hold the instance directly because we want to take ownership of presenter
    //so that it don't de-allocated directly
    var presenter: LoginPresenter?
    weak var delegate: LoginViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown(notificatin:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fieldContainerView: UIView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: SMFloatingLabelTextField!
    @IBOutlet weak var logInButton: UIButton!
    var activityIndicatorView: UIActivityIndicatorView?
    var activeTextField: UITextField? = nil
    

    private func setupViews() {
        
        fieldContainerView.layer.cornerRadius = 4.0
        logInButton.layer.cornerRadius = 4.0
        let disabledBackgroundColor = UIColor(colorLiteralRed: 0/255.0, green: 92/255.0, blue: 176/255.0, alpha: 1.0)
        let disabledBackgroundImage = UIImage.image(from: disabledBackgroundColor, size: CGSize(width: 1.0, height: 1.0)).resizableImage(withCapInsets: .zero)
        logInButton.setBackgroundImage(disabledBackgroundImage, for: .disabled)
        let enabeldBackgroundImage = UIImage.image(from: UIColor.white, size: CGSize(width: 1.0, height: 1.0)).resizableImage(withCapInsets: .zero)
        logInButton.setBackgroundImage(enabeldBackgroundImage, for: .normal)
        let disabledTitleColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        logInButton.setTitleColor(disabledTitleColor, for: .disabled)
        let enabledTitleColor = UIColor(colorLiteralRed:0.15, green:0.56, blue:0.94, alpha:1)
        logInButton.setTitleColor(enabledTitleColor, for: .normal)
        logInButton.isEnabled = false
        logInButton.clipsToBounds = true
        
        let toggleButton = UIButton(type:.custom)
        toggleButton.setImage(#imageLiteral(resourceName: "eyeIcon"), for: .normal)
        toggleButton.addTarget(self, action: #selector(LoginViewController.toggleSecureText(_:)), for: .touchUpInside)
        toggleButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        passwordField.rightView = toggleButton
        passwordField.rightViewMode = .always
    }
    
    func toggleSecureText(_ sender: UIButton) {
        passwordField.isSecureTextEntry = !passwordField.isSecureTextEntry
    }
    
    func showActivityIndicator() {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        view.addSubview(activityIndicatorView!)
        activityIndicatorView?.snp.makeConstraints({ make in
            make.center.equalTo(view)
        })
        activityIndicatorView?.hidesWhenStopped = true
        activityIndicatorView?.startAnimating()
        view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view?.alpha = 0.8
        }
    }
    
    func hideActivityIndicator() {
        activityIndicatorView?.stopAnimating()
        activityIndicatorView = nil
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1.0
        })
        view.isUserInteractionEnabled = true
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        guard let username = usernameField.text, let password = passwordField.text else {
            return
        }
        presenter?.loginWith(username: username, password: password)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        
        var emailTextField: UITextField?
        let alertController = UIAlertController(title: Strings.resetPasswordTitle, message: Strings.resetPasswordPopupText, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: Strings.cancel, style: .default, handler: {_ in return} )
        )
        alertController.addAction(
            UIAlertAction(title: Strings.ok, style: .default, handler: { _ in
                guard let email = emailTextField?.text else {
                    return
                }
                
                alertController.dismiss(animated: true, completion: nil)
                self.presenter?.forgotPassword(withEmailID: email)
            })
        )
        alertController.addTextField { textField in
            //replace this with a strings constant but i currently don't know how 
            //that file is autogenerated...
            textField.placeholder = OEXLocalizedString("EMAIL_ID_PLACEHOLDER", nil)
            emailTextField = textField
        }
        present(alertController, animated: true, completion: nil)
    }
    
    
    
    @IBAction func textChanged(_ sender: UITextField) {
        if usernameField.text?.isEmpty == false && passwordField.text?.isEmpty == false {
            logInButton.isEnabled = true
        } else {
            logInButton.isEnabled = false
        }
    }
    
    func keyboardWasShown(notificatin: Notification) {
        guard let info = notificatin.userInfo,
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size else  {
                return
        }
        scrollView.contentSize = scrollView.frame.size
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
        
        if let originInParent = activeTextField.map ({
           fieldContainerView.convert($0.frame.origin, to: view)
        }), let frameInParent = activeTextField.map( {
            fieldContainerView.convert($0.frame, to: view)
        }) {
            var rect = view.frame
            rect.size.height -= keyboardSize.height
            if !rect.contains(originInParent) {
                scrollView.scrollRectToVisible(frameInParent, animated: true)
            }
        }
    }
    
    func keyboardWillHide(notification: Notification) {
        let inset = UIEdgeInsets.zero
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
    }
}

extension LoginViewController : LoginView {
    
    func present(message: Message) {
        UIAlertController().showAlertWithTitle(message.title, message: message.message, onViewController: self)
    }
    
    func loginSuccessfull() {
        view.endEditing(true)
        delegate?.loginViewControllerDidLogin(self)
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}
