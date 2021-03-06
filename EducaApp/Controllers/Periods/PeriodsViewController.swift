//
//  PeriodsTableViewController.swift
//  EducaApp
//
//  Created by Gloria Cisneros on 19/10/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

class PeriodsViewController: BaseFilterViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var shadowView: UIView!
  @IBOutlet weak var noReportsLabel: UILabel!
  @IBOutlet weak var menuContentView: UIView!
  @IBOutlet weak var menuHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var customLoader: CustomActivityIndicatorView!
  
  @IBOutlet weak var downloadButton: UIButton!
  
  @IBOutlet weak var downLoadLabel: UILabel!
  
  let UserListSegueIdentifier = "GoToUserListSegue"
  let DocumentPreviewSegueIdentifier = "GoToDocumentPreviewSegue"
  
  let refreshDataSelector: Selector = "refreshData"
  let refreshControl = CustomRefreshControlView()
  
  var documents = [Document]()
  var initialHeightConstraintConstant: CGFloat?
  var isRefreshing: Bool?
  var selectedDocument: Document?
  var downloadedDocument: Document?
  
  var selectedCell: DocumentTableViewCell?
  var downLoadedCell: DocumentTableViewCell?
  
  var currentDownloadSize: Int64?
  var currentDownloadData = NSMutableData()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupElements()
    setupDocuments()
    setupTableView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Private
  
  private func setupElements() {
    setupSearchBar()
    setupMenuView()
  }
  
  private func setupMenuView() {
    initialHeightConstraintConstant = menuHeightConstraint.constant
    menuContentView.clipsToBounds = true
    menuHeightConstraint.constant = 0
  }
  
  private func setupTableView() {
    tableView.tableFooterView = UIView()
    tableView.addSubview(refreshControl)
    refreshControl.addTarget(self, action: refreshDataSelector, forControlEvents: UIControlEvents.ValueChanged)
  }
  
  private func setupDocuments() {
    documents = Document.getAllReports(self.dataLayer.managedObjectContext!)
    guard documents.count == 0 else {
      getDocuments()
      return
    }
    tableView.hidden = true
    customLoader.startActivity()
    getDocuments()
  }
  
  private func getDocuments() {
    DocumentService.fetchReports({(responseObject: AnyObject?, error: NSError?) in
      print(responseObject)
      print(error.debugDescription)
      self.refreshControl.endRefreshing()
      self.isRefreshing = false
      guard let json = responseObject as? Array<NSDictionary> where json.count > 0 else {
        if Util.connectedToNetwork() {
          self.noReportsLabel.hidden = false
          self.tableView.hidden = true
        }
        self.customLoader.stopActivity()
        return
      }
      if (json[0][Constants.Api.ErrorKey] == nil) {
        let syncedDocuments = Document.syncWithJsonArray(json, areSessionDocuments: false, ctx: self.dataLayer.managedObjectContext!)
        self.documents = syncedDocuments
        self.dataLayer.saveContext()
        self.reloadData()
      }
    })
  }
  
  private func showMenuView() {
    hideSearchBarAnimated(false)
    validateDocumentAvailibity()
    self.shadowView.translatesAutoresizingMaskIntoConstraints = true
    self.menuContentView.translatesAutoresizingMaskIntoConstraints = true
    self.navigationController?.interactivePopGestureRecognizer?.enabled = false
    self.navigationController?.view.addSubview(self.shadowView)
    self.navigationController?.view.addSubview(self.menuContentView)
    UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
      self.shadowView.alpha = 0.35
      self.menuContentView.frame = CGRect(x: self.menuContentView.frame.origin.x, y: self.menuContentView.frame.origin.y - self.initialHeightConstraintConstant!, width: self.menuContentView.frame.width, height: self.initialHeightConstraintConstant!)
      }, completion: nil)
    shadowView.userInteractionEnabled = true
  }
  
  private func hideMenuViewWithoutAnimation () {
    self.navigationController?.interactivePopGestureRecognizer?.enabled = true
    self.shadowView.alpha = 0.0
    self.menuContentView.frame = CGRect(x: self.menuContentView.frame.origin.x, y: self.menuContentView.frame.origin.y + self.initialHeightConstraintConstant!, width: self.menuContentView.frame.width, height: self.initialHeightConstraintConstant!)
  }
  
  private func hideSearchBarAnimated(animated: Bool) {
    let duration = animated ? 0.3 : 0
    searchBar.resignFirstResponder()
    UIView.animateWithDuration(duration, animations: {
      self.navigationItem.titleView?.alpha = 0
      }, completion: { finished in
        self.setupBarButtonItem()
        self.navigationItem.title = "Periodos"
        self.navigationItem.titleView = nil
    })
  }
  
  private func validateDocumentAvailibity() {
    if selectedDocument?.isSaved == true {
      downloadButton.enabled = false
      downLoadLabel.textColor = UIColor.lightGrayColor()
    } else {
      downloadButton.enabled = true
      downLoadLabel.textColor = UIColor.defaultTextColor()
    }
  }
  
  // MARK: - Public
  
  func refreshData() {
    isRefreshing = true
    Util.delay(2.0) {
      self.getDocuments()
    }
  }
  
  func reloadData() {
    guard self.isRefreshing == false else {
      self.tableView.reloadData()
      return
    }
    Util.delay(0.5) {
      self.customLoader.stopActivity()
      self.tableView.hidden = false
      self.tableView.reloadData()
    }
  }
  
  // MARK: - Actions
  
  @IBAction func goBack(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func hideMenuView(sender: AnyObject) {
    self.navigationController?.interactivePopGestureRecognizer?.enabled = true
    UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
      self.hideMenuViewWithoutAnimation()
      }, completion: nil)
  }
  
  @IBAction func showSearchBar(sender: AnyObject) {
    navigationItem.titleView = searchBar
    searchBar.alpha = 0
    UIView.animateWithDuration(0.5, animations: {
      self.searchBar.alpha = 1
      self.searchBar.becomeFirstResponder()
      }, completion: { finished in
    })
  }
  
  @IBAction func goToUsersList(sender: AnyObject) {
    hideMenuViewWithoutAnimation()
    performSegueWithIdentifier(UserListSegueIdentifier, sender: nil)
  }
  
  @IBAction func goToDocumentPreview(sender: AnyObject) {
    hideMenuView(NSNull)
    performSegueWithIdentifier(DocumentPreviewSegueIdentifier, sender: nil)
  }
  
  @IBAction func downloadDocument(sender: AnyObject) {
    if Util.connectedToNetwork() == false {
      Util.showNoInternetAlert(self)
      return
    }
    hideMenuView(NSNull)
    downLoadedCell = selectedCell
    downloadedDocument = selectedDocument
    guard let url = NSURL(string: "\(Constants.Path.BaseUrl)\((selectedDocument?.url)!)" ) else {
      showAlertWithTitle("Error", message: "No se pudo descargar el archivo.", buttonTitle: "OK")
      return
    }
    let requestObject = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 10.0)
    let urlConnection = NSURLConnection(request: requestObject, delegate: self, startImmediately: true)
    print(urlConnection)
  }
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if (segue.destinationViewController is UsersViewController) {
      let destinationVC = segue.destinationViewController as! UsersViewController;
      destinationVC.documentUsers = selectedDocument!.users.allObjects as? [DocumentUser]
    } else if segue.destinationViewController is UINavigationController {
      let navigationController = segue.destinationViewController as! UINavigationController
      if navigationController.viewControllers.first is DocumentPreviewViewController {
        let destinationVC = navigationController.viewControllers.first as! DocumentPreviewViewController
        destinationVC.document = selectedDocument
        destinationVC.isReport = true
      }
    }
  }
  
  // MARK: - UISearchBarDelegate
  
  func searchBarCancelButtonClicked(searchBar: UISearchBar) {
    hideSearchBarAnimated(true)
  }
  
}


// MARK: - UITableViewDataSource

extension PeriodsViewController: UITableViewDataSource {
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (documents.count)
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(DocumentCellIdentifier, forIndexPath: indexPath) as! DocumentTableViewCell
    cell.setupDocument(documents[indexPath.row] )
    cell.delegate = self
    return cell
  }
  
}

// MARK: - UITableViewDelegate

extension PeriodsViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    selectedDocument = documents[indexPath.row]
    selectedCell = tableView.cellForRowAtIndexPath(indexPath) as? DocumentTableViewCell
    showMenuView()
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
}

// MARK: - UIScrollViewDelegate

extension PeriodsViewController: UIScrollViewDelegate {
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    guard refreshControl.refreshing && !refreshControl.isAnimating else {
      return
    }
    refreshControl.animateRefreshFirstStep()
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    var offset = scrollView.contentOffset.y * -1
    var alpha = CGFloat(0.0)
    offset = offset - 64
    if offset > 30 {
      alpha = ((offset) / 100)
      if alpha > 100 {
        alpha = 1.0
      }
    }
    refreshControl.customView.alpha = alpha
  }
  
}

// MARK: - NSURLConnectionDataDelegate

extension PeriodsViewController: NSURLConnectionDataDelegate {
  
  func connectionDidFinishLoading(connection: NSURLConnection) {
    let doc = Document.getDocumentsById((downloadedDocument?.id)!, ctx: dataLayer.managedObjectContext!)
    doc?.isSaved = true
    dataLayer.saveContext()
    downLoadedCell?.setupProgressView(1.0)
  }
  
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
    currentDownloadSize = response.expectedContentLength
  }
  
  func connection(connection: NSURLConnection, didReceiveData data: NSData) {
    currentDownloadData.appendData(data)
    let downloadProgress: Float = Float((currentDownloadData.length)) / Float(currentDownloadSize!)
    downLoadedCell?.setupProgressView(downloadProgress)
    if downloadProgress == 1.0 {
      Util.showAlertWithTitle(self, title: "Enhorabuena", message: "La descarga se realizó con éxito.", buttonTitle: "OK")
      currentDownloadData = NSMutableData()
    }
  }
  
}

// MARK: - DocumentTableViewCellDelegate

extension PeriodsViewController: DocumentTableViewCellDelegate {
  
  func documentTableViewCell(documentTableViewCell: DocumentTableViewCell, menuButtonDidTapped button: UIButton) {
    showMenuView()
  }
  
}

