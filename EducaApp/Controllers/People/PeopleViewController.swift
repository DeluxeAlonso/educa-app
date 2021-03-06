//
//  PeopleViewController.swift
//  EducaApp
//
//  Created by Alonso on 10/19/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

enum SelectedSegmentIndex: Int {
  case Users
  case Students
}

let StudentCellIdentifier = "StudentCell"
let StudentsFilterViewControllerIdentifier = "StudentsFilterViewController"

class PeopleViewController: BaseFilterViewController {
  
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var mapButton: UIBarButtonItem!
  @IBOutlet weak var customLoader: CustomActivityIndicatorView!
  
  let userAdvancedSearchSelector: Selector = "showAdvancedUserSearchPopup:"
  let studentAdvancedSearchSelector: Selector = "showAdvancedStudentSearchPopup:"
  let refreshDataSelector: Selector = "refreshData"
  let refreshControl = CustomRefreshControlView()
  
  var isRefreshing = false
  var popupViewController: STPopupController?
  var selectedSegmentIndex: Int?
  var users = [User]()
  var students = [Student]()
  
  var userSearchString: String?
  var studentSearchString: String?
  
  var mapBarButtonItem = UIBarButtonItem()
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupElements()
    setupUsers()
  }
  
  // MARK: - Private
  
  private func setupElements() {
    if currentUser?.hasPermissionWithId(28) == false {
      mapButton.image = nil
      mapButton.enabled = false
    }
    mapBarButtonItem = mapButton
    selectedSegmentIndex = SelectedSegmentIndex.Users.hashValue
    advanceSearchBarButtonItem.action = userAdvancedSearchSelector
    tableView.tableFooterView = UIView()
  }
  
  private func setupUsers() {
    users = User.getAllUsers(self.dataLayer.managedObjectContext!)
    students = Student.getAllStudents(self.dataLayer.managedObjectContext!)
    guard users.count == 0 else {
      getUsers()
      getStudents()
      return
    }
    self.tableView.hidden = true
    customLoader.startActivity()
    getUsers()
  }
  
  private func getUsers() {
    UserService.fetchUsers({(responseObject: AnyObject?, error: NSError?) in
      self.refreshControl.endRefreshing()
      self.isRefreshing = false
      guard let json = responseObject as? Array<NSDictionary> where json.count > 0 else {
        self.customLoader.stopActivity()
        self.tableView.hidden = false
        return
      }
      if (json[0][Constants.Api.ErrorKey] == nil) {
        let syncedUsers = User.syncWithJsonArray(json , ctx: self.dataLayer.managedObjectContext!)
        self.users = syncedUsers
        self.dataLayer.saveContext()
        self.tableView.reloadData()
      }
    })
  }
  
  private func getStudents() {
    StudentService.fetchStudents({(responseObject: AnyObject?, error: NSError?) in
      self.refreshControl.endRefreshing()
      self.isRefreshing = false
      guard let json = responseObject as? Array<NSDictionary> where json.count > 0 else {
        return
      }
      if (json[0][Constants.Api.ErrorKey] == nil) {
        let syncedStudents = Student.syncWithJsonArray(json , ctx: self.dataLayer.managedObjectContext!)
        self.students = syncedStudents
        self.dataLayer.saveContext()
        self.tableView.reloadData()
      }
    })
  }
  
  private func setupPopupNavigationBar() {
    STPopupNavigationBar.appearance().barTintColor = UIColor.defaultTextColor()
    STPopupNavigationBar.appearance().tintColor = UIColor.whiteColor()
    STPopupNavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.lightFontWithFontSize(17)]
  }
  
  private func hideSearchBar() {
    let duration = 0.3
    searchBar.resignFirstResponder()
    setupSearchButton()
    UIView.animateWithDuration(duration, animations: {
      self.navigationItem.titleView?.alpha = 0
      }, completion: { finished in
        self.navigationItem.setRightBarButtonItems([self.simpleSearchBarButtonItem, self.mapBarButtonItem], animated: true)
        self.navigationItem.title = "Personas"
        self.navigationItem.titleView = nil
    })
  }
  
  // MARK: - Actions
  
  @IBAction func selectedControlIndexChanged(sender: AnyObject) {
    resetSearchFields()
    selectedSegmentIndex = segmentedControl.selectedSegmentIndex
    advanceSearchBarButtonItem.action = selectedSegmentIndex == SelectedSegmentIndex.Users.rawValue ? userAdvancedSearchSelector : studentAdvancedSearchSelector
    tableView.reloadData()
  }
  
  @IBAction func showSearchBar(sender: AnyObject) {
    navigationItem.titleView = searchBar
    navigationItem.setRightBarButtonItems([advanceSearchBarButtonItem], animated: true)
    searchBar.alpha = 0
    setupAdvancedSearchButton()
    UIView.animateWithDuration(0.5, animations: {
      self.searchBar.alpha = 1
      self.searchBar.becomeFirstResponder()
      }, completion: { finished in
        
    })
  }
  
  @IBAction func showAdvancedUserSearchPopup(sender: AnyObject) {
    hideSearchBar()
    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier(UsersFilterViewControllerIdentifier) as! UsersFilterViewController
    viewController.delegate = self
    viewController.nameSearchString = userSearchString
    setupPopupNavigationBar()
    popupViewController = STPopupController(rootViewController: viewController)
    popupViewController!.presentInViewController(self)
  }
  
  @IBAction func showAdvancedStudentSearchPopup(sender: AnyObject) {
    hideSearchBar()
    let viewController = self.storyboard?.instantiateViewControllerWithIdentifier(StudentsFilterViewControllerIdentifier) as! StudentsFilterViewController
    viewController.delegate = self
    viewController.nameSearchString = studentSearchString
    setupPopupNavigationBar()
    popupViewController = STPopupController(rootViewController: viewController)
    popupViewController!.presentInViewController(self)
  }
  
}

extension PeopleViewController: UITableViewDataSource {
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return selectedSegmentIndex! == SelectedSegmentIndex.Users.rawValue ? users.count : (students.count)
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell?
    switch selectedSegmentIndex {
    case SelectedSegmentIndex.Users.rawValue?:
      cell = tableView.dequeueReusableCellWithIdentifier(UserTableViewCellIdentifier, forIndexPath: indexPath)
      (cell as! UserTableViewCell).setupUser(users[indexPath.row] )
    default:
      cell = tableView.dequeueReusableCellWithIdentifier(StudentCellIdentifier, forIndexPath: indexPath) as! StudentTableViewCell
      (cell as! StudentTableViewCell).setupStudent(students[indexPath.row])
    }
    return cell!
  }
  
}

// MARK: - UISearchBarDelegate

extension PeopleViewController {
  
  func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    guard let searchText = searchBar.text else {
      return
    }
    selectedSegmentIndex == SelectedSegmentIndex.Users.rawValue ? searchUsers(searchText) : searchStudents(searchText)
  }
  
  func searchBarCancelButtonClicked(searchBar: UISearchBar) {
    resetSearchFields()
    hideSearchBar()
  }
  
  private func searchUsers(searchText: String) {
    userSearchString = searchText
    guard searchText.characters.count != 0 else {
      users = User.getAllUsers(dataLayer.managedObjectContext!)
      tableView.reloadData()
      return
    }
    users = User.searchByName(searchText, ctx: dataLayer.managedObjectContext!)
    tableView.reloadData()
  }
  
  private func searchStudents(searchText: String) {
    studentSearchString = searchText
    guard searchText.characters.count != 0 else {
      students = Student.getAllStudents(dataLayer.managedObjectContext!)
      tableView.reloadData()
      return
    }
    students = Student.searchByName(searchText, ctx: dataLayer.managedObjectContext!)
    tableView.reloadData()
  }
  
  private func resetSearchFields() {
    searchBar.text = ""
    searchUsers("")
    searchStudents("")
  }
  
}

// MARK: - UsersFilterViewControllerDelegate

extension PeopleViewController: UsersFilterViewControllerDelegate {
  
  func usersFilterViewController(usersFilterViewController: UsersFilterViewController, searchedName name: String, searchedDocNumber: String, profile: String) {
    var searchedUsers = name.characters.count == 0 ? User.getAllUsers(dataLayer.managedObjectContext!) : User.searchByName(name, ctx: dataLayer.managedObjectContext!)
    if searchedDocNumber.characters.count > 0 {
      searchedUsers = searchedUsers.filter({ (user) in return user.username.lowercaseString.rangeOfString(searchedDocNumber) != nil })
    }
    if profile != "Todos" {
      searchedUsers = searchedUsers.filter({ (user) in
        let userProfileNames = user.profiles.map({ $0.name }) as [String]
        return userProfileNames.contains(profile)
      })
    }
    users = searchedUsers
    tableView.reloadData()
    popupViewController?.dismiss()
  }
  
}

// MARK: - StudentsFilterViewControllerDelegate

extension PeopleViewController: StudentsFilterViewControllerDelegate {
  
  func studentsFilterViewController(studentsFilterViewController: StudentsFilterViewController, searchedName name: String, minAge: Int, maxAge: Int, gender: Int) {
    var searchedStudents = name.characters.count == 0 ? Student.getAllStudents(dataLayer.managedObjectContext!) : Student.searchByName(name, ctx: dataLayer.managedObjectContext!)
    print(minAge)
    searchedStudents = searchedStudents.filter({ (student) in
      return student.age >= Int32(minAge) && student.age <= Int32(maxAge)
     })
    print(gender)
    if gender != -1 {
      searchedStudents = searchedStudents.filter({ (student) in return student.gender == Int32(gender) })
    }
    students = searchedStudents
    tableView.reloadData()
    popupViewController?.dismiss()
  }
  
}

// MARK: - UIPopoverPresentationControllerDelegate

extension PeopleViewController: UIPopoverPresentationControllerDelegate {
  
  func adaptivePresentationStyleForPresentationController(
    controller: UIPresentationController) -> UIModalPresentationStyle {
      return .None
  }
  
}
