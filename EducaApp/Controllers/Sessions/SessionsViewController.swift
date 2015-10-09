//
//  SessionsViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/20/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

let SessionsCellIdentifier =  "SessionCell"
let SessionDocumentsSegueIdentifier = "GoToDocumentsSegue"
let SessionVolunteersSegueIdentifier = "GoToVolunteersList"
let SessionAssistantsSegueIdentifier = "GoToAssistants"
let SessionMapSegueIdentifier = "GoToSessionMapSegue"

class SessionsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, SessionTableViewCellDelegate {
  
  @IBOutlet weak var menuContentView: UIView!
  @IBOutlet weak var menuHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var shadowView: UIView!
  
  @IBOutlet weak var assistanceView: UIView!
  @IBOutlet weak var documentsView: UIView!
  @IBOutlet weak var mapView: UIView!
  @IBOutlet weak var registerView: UIView!
  
  var initialHeightConstraintConstant: CGFloat?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupMenuView()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Private
  
  private func setupMenuView() {
    initialHeightConstraintConstant = menuHeightConstraint.constant
    menuContentView.clipsToBounds = true
    menuHeightConstraint.constant = 0
  }
  
  private func showMenuView() {
    self.shadowView.translatesAutoresizingMaskIntoConstraints = true
    self.menuContentView.translatesAutoresizingMaskIntoConstraints = true
    self.navigationController?.view.addSubview(self.shadowView)
    self.navigationController?.view.addSubview(self.menuContentView)
    UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
      self.shadowView.alpha = 0.35
      self.menuContentView.frame = CGRect(x: self.menuContentView.frame.origin.x, y: self.menuContentView.frame.origin.y - self.initialHeightConstraintConstant!, width: self.menuContentView.frame.width, height: self.initialHeightConstraintConstant!)
      }, completion: nil)
    shadowView.userInteractionEnabled = true
  }
  
  private func hideMenuViewWithoutAnimation () {
    self.shadowView.alpha = 0.0
    self.menuContentView.frame = CGRect(x: self.menuContentView.frame.origin.x, y: self.menuContentView.frame.origin.y + self.initialHeightConstraintConstant!, width: self.menuContentView.frame.width, height: self.initialHeightConstraintConstant!)
  }
  
  // MARK: - Actions
  
  @IBAction func hideMenuView(sender: AnyObject) {
    UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
        self.hideMenuViewWithoutAnimation()
      }, completion: nil)
  }
  
  @IBAction func goToSessionDocuments(sender: AnyObject) {
    performSegueWithIdentifier(SessionDocumentsSegueIdentifier, sender: nil)
    hideMenuViewWithoutAnimation()
  }
  
  @IBAction func goToSessionMap(sender: AnyObject) {
    hideMenuView(NSNull)
    performSegueWithIdentifier(SessionMapSegueIdentifier, sender: nil)
  }
  
  @IBAction func goToAssistantsList(sender: AnyObject) {
    hideMenuViewWithoutAnimation()
    performSegueWithIdentifier(SessionAssistantsSegueIdentifier, sender: nil)
  }
  
  @IBAction func goToVolunteersList(sender: AnyObject) {
    hideMenuViewWithoutAnimation()
    performSegueWithIdentifier(SessionVolunteersSegueIdentifier, sender: nil)
  }
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if (segue.destinationViewController is DocumentsViewController) {
      let destinationVC = segue.destinationViewController as! DocumentsViewController;
      destinationVC.session = Session()
    }
  }
  
  // MARK: - UITableViewDataSource
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 5
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(SessionsCellIdentifier, forIndexPath: indexPath) as! SessionTableViewCell
    cell.delegate = self
    return cell
  }
  
  // MARK: - UITableViewDelegate
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  // MARK: - SessionTableViewCellDelegate
  
  func sessionTableViewCell(sessionTableViewCell: SessionTableViewCell, menuButtonDidTapped button: UIButton) {
    showMenuView()
  }
  
}
