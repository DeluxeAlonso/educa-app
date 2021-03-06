//
//  SignInViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/3/15.
//  Copyright (c) 2015 Alonso. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {
  
  @IBOutlet weak var logoImageView: UIImageView!
  @IBOutlet weak var trailingLogoConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var usernameContainerView: UIView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var usernameTextField: UITextField!
  
  @IBOutlet weak var passwordContainerView: UIView!
  @IBOutlet weak var passwordLabel: UILabel!
  @IBOutlet weak var passwordTextField: UITextField!
  
  @IBOutlet weak var signInButton: UIButton!
  @IBOutlet weak var loaderIndicator: CustomActivityIndicatorView!
  
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  
  let RecoverPasswordTableViewControllerIdentifier = "RecoverPasswordTableViewController"
  
  let SignInButtonTitle = "Iniciar Sesión"
  let AlertMessageTitle = "Error"
  let AlertButtonTitle = "OK"
  let EmptyUsernamePasswordMessage = "El nombre de usuario y contraseña no pueden estar en blanco."
  let RequestErrorMessage = "Ocurrió un error. Por favor intenta de nuevo."
  let RecoverPasswordSuccessMessage = "Se le ha enviado un correo para la recuperación de su contraseña."
  let RecoverPasswordErrorAlertButton = "OK"
  let RecoverPasswordErrorAlertTitle = "Ocurrió un error."
  
  var initialBottomHeight: CGFloat!
  var isKeyboardVisible = false
  var isPopUpVisible = false
  var recoverPasswordPopUp: STPopupController?

  lazy var dataLayer = DataLayer()
  
  // MARK: - Lifecycle
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil);
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil);
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupElements()
  }
  
  // MARK: - Private
  
  private func setupElements() {
    setupObservers()
    setupInputFields()
    setupAdditionalConstraints()
  }
  
  private func setupObservers() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Constants.KeyboardSelector.WillShow, name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Constants.KeyboardSelector.WillHide, name: UIKeyboardWillHideNotification, object: nil)
  }
  
  private func setupInputFields() {
    usernameTextField.delegate = self
    passwordTextField.delegate = self
    usernameLabel.textColor = UIColor.grayColor()
    passwordLabel.textColor = UIColor.grayColor()
    usernameContainerView.layer.borderColor = UIColor.defaultBorderFieldColor().CGColor
    passwordContainerView.layer.borderColor = UIColor.defaultBorderFieldColor().CGColor
  }
  
  private func setupAdditionalConstraints() {
    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    let screenRect: CGRect = UIScreen.mainScreen().bounds
    initialBottomHeight = screenRect.size.height / 3
    bottomConstraint.constant = initialBottomHeight
  }
  
  private func showEmptyUsernameOrPasswordAlert() {
    let alertController = UIAlertController(title: AlertMessageTitle, message: EmptyUsernamePasswordMessage, preferredStyle: UIAlertControllerStyle.Alert)
    let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alertController.addAction(defaultAction)
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  private func enableSignInButton() {
    loaderIndicator?.stopActivity()
    loaderIndicator?.hidden = true
    signInButton.userInteractionEnabled = true
    signInButton.setTitle(SignInButtonTitle, forState: UIControlState.Normal)
  }
  
  private func disableSignInButton() {
    signInButton.setTitle("", forState: UIControlState.Normal)
    loaderIndicator?.startActivity()
    loaderIndicator?.hidden = false
    signInButton.userInteractionEnabled = false
  }
  
  private func setupPopupNavigationBar() {
    STPopupNavigationBar.appearance().barTintColor = UIColor.defaultTextColor()
    STPopupNavigationBar.appearance().tintColor = UIColor.whiteColor()
    STPopupNavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.lightFontWithFontSize(17)]
  }
  
  private func saveUser(json: NSDictionary) {
    let user = User.updateOrCreateWithJson(json, ctx: self.dataLayer.managedObjectContext!)
    self.dataLayer.saveContext()
    User.setAuthenticatedUser(user!)
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.SignIn, object: self, userInfo: nil)
  }
  
  // MARK: - Public
  
  func recoverPassword(email: String) {
    disableSignInButton()
    UserService.recoverPassword(email, completion: {(responseObject: AnyObject?, error: NSError?) in
      self.enableSignInButton()
      guard let json = responseObject as? NSDictionary else {
        self.recoverPasswordPopUp?.dismiss()
        Util.showAlertWithTitle(self, title: self.AlertMessageTitle, message: self.RequestErrorMessage, buttonTitle: self.AlertButtonTitle)
        return
      }
      if (json[Constants.Api.ErrorKey] == nil) {
        self.recoverPasswordPopUp?.dismiss()
        let alertController = UIAlertController(title: self.RecoverPasswordSuccessMessage, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: self.RecoverPasswordErrorAlertButton, style: UIAlertActionStyle.Default) { action -> Void in
          self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
      } else {
        self.recoverPasswordPopUp?.dismiss()
        Util.showAlertWithTitle(self, title: self.RecoverPasswordErrorAlertTitle, message: json[Constants.Api.ErrorKey] as! String, buttonTitle: self.RecoverPasswordErrorAlertButton)
      }
    })
  }
  
  // MARK: - Actions
  
  @IBAction func hideKeyboard(sender: AnyObject) {
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()
  }
  
  @IBAction func gotoRecoverPassword(sender: AnyObject) {
    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier(RecoverPasswordTableViewControllerIdentifier) as! RecoverPasswordTableViewController
    viewController.delegate = self
    setupPopupNavigationBar()
    recoverPasswordPopUp = STPopupController(rootViewController: viewController)
    recoverPasswordPopUp!.presentInViewController(self)
  }
  
  @IBAction func signIn(sender: AnyObject) {
    let email = usernameTextField.text, password = passwordTextField.text
    guard ( email!.characters.count != 0 || password!.characters.count != 0 ) else {
      showEmptyUsernameOrPasswordAlert()
      return
    }
    disableSignInButton()
    UserService.signInWithEmail(email, password: password, completion: {(responseObject: AnyObject?, error: NSError?) in
      self.enableSignInButton()
      guard let json = responseObject as? NSDictionary else {
        Util.showAlertWithTitle(self, title: self.AlertMessageTitle, message: self.RequestErrorMessage, buttonTitle: self.AlertButtonTitle)
        return
      }
      json[Constants.Api.ErrorKey] == nil ? self.saveUser(json) : Util.showAlertWithTitle(self, title: self.AlertMessageTitle, message: json[Constants.Api.ErrorKey] as! String, buttonTitle: self.AlertButtonTitle)
    })
  }
  
  // MARK: - Notifications
  
  func keyboardWillShow(notification: NSNotification) {
    guard !isKeyboardVisible else {
      return
    }
    isKeyboardVisible = true
    view.layoutIfNeeded()
    if let keyboardFrame: CGRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
      let keyboardHeight = CGFloat(keyboardFrame.size.height) + CGFloat(20)
      let diff: CGFloat = keyboardHeight - CGFloat(bottomConstraint.constant)
      if diff > 0 {
        bottomConstraint.constant = keyboardFrame.size.height + 20
        if let logoOffSet = logoImageView?.frame.origin.y {
          if (logoOffSet - diff < 20) {
            self.logoImageView.alpha = 0.0
          }
        }
        view.layoutIfNeeded()
      }
    }
  }
  
  func keyboardWillHide(notification: NSNotification) {
    guard isKeyboardVisible else {
      return
    }
    isKeyboardVisible = false
    view.layoutIfNeeded()
    bottomConstraint.constant = self.initialBottomHeight
    logoImageView.alpha = 1.0
    view.layoutIfNeeded()
    view.endEditing(true)
  }
  
}

// MARK: - UITextFieldDelegates

extension SignInViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    switch textField.tag {
    case 1:
      passwordTextField.becomeFirstResponder()
      break
    case 2:
      textField.resignFirstResponder()
      signIn(NSNull)
      break
    default:
      break
    }
    return true
  }
  
}
