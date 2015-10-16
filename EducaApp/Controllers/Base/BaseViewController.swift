//
//  BaseViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/24/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

let kBarButtonSelector: Selector = "revealToggle:"

class BaseViewController: UIViewController, SWRevealViewControllerDelegate {
  
  @IBOutlet weak var menuIcon: UIBarButtonItem!
  
  let MenuIconImageName = "MenuIcon"
  
  lazy var dataLayer = DataLayer()
  
  var currentUser: User?
  
  var tapGesture: UITapGestureRecognizer?
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupCurrentUser()
    setupNavigationBar()
    setupBarButtonItem()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(true)
    view.endEditing(true)
    setupPanGesture()
  }
  
  override func viewWillDisappear(animated: Bool) {
    guard let recognizers = self.view.gestureRecognizers else {
      return
    }
    for recognizer in recognizers {
      self.view.removeGestureRecognizer(recognizer)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Public
  
  func setupCurrentUser() {
    currentUser = User.getAuthenticatedUser(dataLayer.managedObjectContext!)
  }
  
  func setupNavigationBar() {
    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
    view.backgroundColor = UIColor.defaultBackgroundColor()
    navigationController?.navigationBar.barTintColor = UIColor.defaultTextColor()
    navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
  }
  
  func setupBarButtonItem() {
    if self.revealViewController() != nil {
      menuIcon?.target = self.revealViewController()
      menuIcon?.action = kBarButtonSelector
      view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
  }
  
  // MARK: - Private
  
  private func setupPanGesture() {
    self.revealViewController().delegate = self
    if self.revealViewController() != nil {
      self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
  }
  
  // MARK: - SWRevealViewControllerDelegate
  
  func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
    if position == FrontViewPosition.Right {
      view.endEditing(true)
      UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    } else if position == FrontViewPosition.Left {
      UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
  }
  
}
