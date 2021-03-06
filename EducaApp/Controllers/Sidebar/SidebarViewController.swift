//
//  SidebarViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/14/15.
//  Copyright (c) 2015 Alonso. All rights reserved.
//

import UIKit

class MenuController: StaticDataTableViewController {
  
  @IBOutlet weak var PostulationCell: UITableViewCell!
  @IBOutlet weak var NewsCell: UITableViewCell!
  @IBOutlet weak var BlogCell: UITableViewCell!
  @IBOutlet weak var PeopleCell: UITableViewCell!
  @IBOutlet weak var SesionsCell: UITableViewCell!
  @IBOutlet weak var DocumentsCell: UITableViewCell!
  @IBOutlet weak var CameraCell: UITableViewCell!
  @IBOutlet weak var PayCell: UITableViewCell!
  @IBOutlet weak var DonationCell: UITableViewCell!
  @IBOutlet weak var ReportsCell: UITableViewCell!
  @IBOutlet weak var SettingsCell: UITableViewCell!
  @IBOutlet weak var periodLabel: UILabel!
  
  let PostulationSuccessTitle = "Enhorabuena"
  let PostulationSuccessMessage = "Has logrado postular con éxito"
  let PostulationSuccessButtonTitle = "OK"
  
  var currentUser: User?
  lazy var dataLayer = DataLayer()
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupMenuItems()
  }
  
  // MARK: - Private
  
  private func setupMenuItems() {
    currentUser = User.getAuthenticatedUser(dataLayer.managedObjectContext!)
    periodLabel.text = "\((currentUser?.periodName)!)"
    setupPermissions()
    for action in (currentUser?.actions)! {
      let idnumber = (action as! Action).id
      switch idnumber{
      case 12:
        self.cell(SesionsCell, setHidden: false)
        self.cell(DocumentsCell, setHidden: false)
      case 15:
        self.cell(SesionsCell, setHidden: false)
        self.cell(DocumentsCell, setHidden: false)
      case 14:
        break;
      case 16:
        break;
      case 28:
        break;
      case 35:
        self.cell(PeopleCell, setHidden: false)
      case 21:
        self.cell(ReportsCell, setHidden: false)
      case 39:
        self.cell(ReportsCell, setHidden: false)
      case 24:
        self.cell(PayCell, setHidden: false)
      default:
        self.cell(DonationCell, setHidden: false)
        self.cell(CameraCell, setHidden: false)
        self.cell(NewsCell, setHidden: false)
        self.cell(SettingsCell, setHidden: false)
      }
      if (currentUser?.isWebMaster() == true) {
        self.cell(PayCell, setHidden: true)
      }
      if currentUser?.isOnlyGodfather() == true {
        self.cell(CameraCell, setHidden: true)
      }
      self.reloadDataAnimated(false)
    }
  }
  
  private func setupPermissions() {
    if currentUser?.canReapply == false {
      self.cell(PostulationCell, setHidden: true)
    }
    self.cell(NewsCell, setHidden: true)
    self.cell(BlogCell, setHidden: true)
    self.cell(PeopleCell, setHidden: true)
    self.cell(SesionsCell, setHidden: true)
    self.cell(DocumentsCell, setHidden: true)
    self.cell(CameraCell, setHidden: true)
    self.cell(PayCell, setHidden: true)
    self.cell(DonationCell, setHidden: true)
    self.cell(ReportsCell, setHidden: true)
    self.cell(SettingsCell, setHidden: true)
    self.reloadDataAnimated(false)
  }
  
  func reaply(idperiod:Int) {
    UserService.reapply(idperiod , completion: {(responseObject: AnyObject?, error: NSError?) in
      guard let json = responseObject as? NSDictionary else {
        return
      }
      self.cell(self.PostulationCell, setHidden: true)
      if (json[Constants.Api.ErrorKey] == nil) {
        let user = User.getUserById((self.currentUser?.id)!, ctx: self.dataLayer.managedObjectContext!)
        user?.canReapply = false
        self.dataLayer.saveContext()
        self.cell(self.PostulationCell, setHidden: true)
        self.reloadDataAnimated(false)
        Util.showAlertWithTitle(self, title: self.PostulationSuccessTitle, message: self.PostulationSuccessMessage, buttonTitle: self.PostulationSuccessButtonTitle)
      }
    })
  }
  
  // MARK: - Actions
  
  @IBAction func selectedNewPostulation(sender: AnyObject) {
    let actionSheetController: UIAlertController = UIAlertController(title: "¿Está seguro de que desea participar en este periodo?", message: nil, preferredStyle: .Alert)
    let payPalAction: UIAlertAction = UIAlertAction(title: "Cancelar", style:UIAlertActionStyle.Cancel, handler: nil)
    actionSheetController.addAction(payPalAction)
    let depositAction: UIAlertAction = UIAlertAction(title: "Aceptar", style: UIAlertActionStyle.Default) { action -> Void in
      self.reapply(NSNull)
    }
    actionSheetController.addAction(depositAction)
    self.presentViewController(actionSheetController, animated: true, completion: nil)
  }
  
  @IBAction func reapply(sender: AnyObject) {
    reaply(Int((currentUser?.periodId)!))
  }
  
  // MARK: - UITableViewDelegate
  
  override func tableView(tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath) {
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }

}
