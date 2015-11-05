//
//  AssistantsViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/22/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

let AssistantCellIdentifier = "AssistantCell"

class AssistantsViewController: BaseViewController {
  
  @IBOutlet weak var customView: UIView!
  
  let GoToCommentViewSegueIdentifier = "ShowCommentSegue"
  let GoToDetailViewSegueIdentifier = "GoToAssistantDetail"
  
  var sessionStudents = [SessionStudent]()
  var selectedCell: UITableViewCell?
  
  var sendCommentPopupViewController: STPopupController?

  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: - Private
  
  private func setupPopupNavigationBar() {
    STPopupNavigationBar.appearance().barTintColor = UIColor.defaultTextColor()
    STPopupNavigationBar.appearance().tintColor = UIColor.whiteColor()
    STPopupNavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.lightFontWithFontSize(17)]
  }
  
  private func goToCommentSection(tableView:UITableView, indexPath: NSIndexPath) {
    selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! AssistantTableViewCell
    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier(SendAssistantCommentViewIdentifier) as! SendAssistantCommentViewController
    viewController.assistant = sessionStudents[indexPath.row].student.fullName
    viewController.delegate = self
    setupPopupNavigationBar()
    sendCommentPopupViewController = STPopupController(rootViewController: viewController)
    sendCommentPopupViewController!.presentInViewController(self)

  }
  
  private func goToDetailSection(tableView:UITableView, indexPath: NSIndexPath) {
    self.performSegueWithIdentifier(GoToDetailViewSegueIdentifier, sender: sessionStudents[indexPath.row].student)
  }
  
  // MARK: - Public
  
  func checkCommentedAssistant() {
    guard let cell = selectedCell as? AssistantTableViewCell else {
      return
    }
    cell.setupCommentedImage()
  }
  
  func dismissSendCommentPopup() {
    sendCommentPopupViewController!.dismiss()
  }
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.destinationViewController is AssistantDetailViewController {
      let destinationVC = segue.destinationViewController as! AssistantDetailViewController
      destinationVC.student = sender as? Student
    }
  }
  
}

// MARK: - UITableViewDataSource

extension AssistantsViewController: UITableViewDataSource {
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sessionStudents.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(AssistantCellIdentifier, forIndexPath: indexPath) as! AssistantTableViewCell
    cell.setupAssistant(sessionStudents[indexPath.row])
    return cell
  }
  
}

//  MARK: - UITableViewDelegate

extension AssistantsViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    ((currentUser?.canListAssistantsComments()) == true) ? goToDetailSection(tableView, indexPath: indexPath) : goToCommentSection(tableView, indexPath: indexPath)
  }
  
}

// MARK: - UIPopoverPresentationControllerDelegate

extension AssistantsViewController: UIPopoverPresentationControllerDelegate {
  
  func adaptivePresentationStyleForPresentationController(
    controller: UIPresentationController) -> UIModalPresentationStyle {
      return .None
  }
  
}
