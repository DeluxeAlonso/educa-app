//
//  ArticlesViewController.swift
//  EducaApp
//
//  Created by Alonso on 9/1/15.
//  Copyright (c) 2015 Alonso. All rights reserved.
//

import UIKit

let ArticlesCellIdentifier = "ArticleCell"
let GoToArticleDetailSegueIdentifier = "GoToArticleDetailSegue"

class ArticlesViewController: BaseFilterViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var customLoader: CustomActivityIndicatorView!
  @IBOutlet weak var favoritesSegmentedControl: UISegmentedControl!
  
  let refreshDataSelector: Selector = "refreshData"
  let refreshControl = CustomRefreshControlView()
  
  var articles = [Article]()
  var labelsArray: Array<UILabel> = []
  var isRefreshing = false
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupElements()
    setupArticles()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.layer.removeAllAnimations()
  }
  
  // MARK: - Private
  
  private func setupElements() {
    setupPendingRequests()
    setupTableView()
  }
  
  private func setupPendingRequests() {
    setupMeetingPointsPendingRequest()
    setupVolunteersAttendancePendingRequest()
  }
  
  private func setupTableView() {
    tableView.tableFooterView = UIView()
    self.tableView.estimatedRowHeight = 243
    self.tableView.rowHeight = UITableViewAutomaticDimension
    tableView.addSubview(refreshControl)
    refreshControl.addTarget(self, action: refreshDataSelector, forControlEvents: UIControlEvents.ValueChanged)
  }
  
  private func setupArticles() {
    articles = Article.getAllArticles(self.dataLayer.managedObjectContext!)
    guard articles.count == 0 else {
      getArticles()
      return
    }
    self.tableView.hidden = true
    customLoader.startActivity()
    getArticles()
  }
  
  private func getArticles() {
    ArticleService.fetchArticles({(responseObject: AnyObject?, error: NSError?) in
      print(responseObject)
      print(error)
      self.refreshControl.endRefreshing()
      self.isRefreshing = false
      let json = responseObject
      if (json != nil && json?["error"] == nil) {
        let syncedArticles = Article.syncWithJsonArray(json as! Array<NSDictionary>, ctx: self.dataLayer.managedObjectContext!)
        self.articles = syncedArticles
        print(self.articles.count)
        self.dataLayer.saveContext()
        if self.favoritesSegmentedControl.selectedSegmentIndex == 0 {
          self.reloadData()
        }
      } else {
        //Show Error Message
      }
    })
  }
  
  private func showAllArticles() {
    tableView.addSubview(refreshControl)
    articles = Article.getAllArticles(self.dataLayer.managedObjectContext!)
    tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
  }
  
  private func showAllFavoriteArticles() {
    refreshControl.endRefreshing()
    refreshControl.removeFromSuperview()
    let favorites = articles.filter { (article) in article.favoritedByCurrentUser == true }
    self.articles = favorites
    tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
  }
  
  private func quickSearchDocument(searchText: String) {
    articles = searchText == "" ? Article.getAllArticles(dataLayer.managedObjectContext!) : Article.searchByTitle(searchText, ctx: dataLayer.managedObjectContext!)
    tableView.reloadData()
  }
  
  private func hideSearchBarAnimated(animated: Bool) {
    let duration = animated ? 0.3 : 0
    searchBar.resignFirstResponder()
    UIView.animateWithDuration(duration, animations: {
      self.navigationItem.titleView?.alpha = 0
      }, completion: { finished in
        self.setupBarButtonItem()
        self.navigationItem.title = "Noticias"
        self.navigationItem.titleView = nil
    })
  }
  
  // MARK: - Public
  
  func refreshData() {
    isRefreshing = true
    Util.delay(2.0) {
      self.getArticles()
    }
  }
  
  func reloadData() {
    guard !self.isRefreshing else {
      self.tableView.reloadData()
      return
    }
    Util.delay(0.5) {
      self.customLoader.stopActivity()
      self.tableView.hidden = false
      self.tableView.reloadData()
    }
  }
  
  func searchBarCancelButtonClicked(searchBar: UISearchBar) {
    searchBar.text = ""
    quickSearchDocument("")
    hideSearchBarAnimated(true)
  }
  
  func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    guard let searchText = searchBar.text else {
      return
    }
    quickSearchDocument(searchText)
  }
  
  // MARK: - Actions
  
  @IBAction func segmentedControlIndexChanged(sender: AnyObject) {
    favoritesSegmentedControl.selectedSegmentIndex == 0 ? showAllArticles() : showAllFavoriteArticles()
  }
  
  // MARK: - Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.destinationViewController is ArticleDetailViewController {
      let destinationVC = segue.destinationViewController as! ArticleDetailViewController
      destinationVC.article = sender as? Article
    }
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
  
}

// MARK: - UITableViewDataSource

extension ArticlesViewController: UITableViewDataSource {
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return articles.count
  }
  
  func tableView(tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCellWithIdentifier(ArticlesCellIdentifier, forIndexPath: indexPath) as! ArticleTableViewCell
      cell.delegate = self
      print(self.view.frame.height / 4)
      cell.setupArticle(articles[indexPath.row], indexPath: indexPath, height: self.view.frame.height / 4)
      return cell
  }

}

// MARK: - UITableViewDelegate

extension ArticlesViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath) {
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
      self.performSegueWithIdentifier(GoToArticleDetailSegueIdentifier, sender: articles[indexPath.row])
  }
  
}

// MARK: - UIScrollViewDelegate

extension ArticlesViewController: UIScrollViewDelegate {
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    guard refreshControl.refreshing && !refreshControl.isAnimating else {
      return
    }
    refreshControl.animateRefreshFirstStep()
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let offset = scrollView.contentOffset.y * -1
    var alpha = CGFloat(0.0)
    if offset > 30 {
      alpha = ((offset) / 100)
      if alpha > 100 {
        alpha = 1.0
      }
    }
    refreshControl.customView.alpha = alpha
  }
  
}

// MARK: - ArticleTableViewCellDelegate

extension ArticlesViewController: ArticleTableViewCellDelegate {
  
  func articleTableViewCell(sessionTableViewCell: ArticleTableViewCell, starButtonDidTapped button: UIButton, favorited: Bool, indexPath: NSIndexPath) {
    currentUser!.updateFavoriteArticle(articles[indexPath.row], favorited: favorited, ctx: dataLayer.managedObjectContext!)
    self.dataLayer.saveContext()
    if favoritesSegmentedControl.selectedSegmentIndex == 1 && !favorited {
      let favorites = articles.filter { (article) in article.favoritedByCurrentUser == true }
      articles = favorites
      tableView.beginUpdates()
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
      tableView.endUpdates()
      tableView.reloadData()
    }
  }
  
}

// MARK: - Pending Requests

extension ArticlesViewController {
  
  private func setupMeetingPointsPendingRequest() {
    guard let parameters = NSUserDefaults.standardUserDefaults().objectForKey("edit_points") as? NSDictionary else {
      return
    }
    SessionService.editReunionPoints(parameters, completion: {(responseObject: AnyObject?, error: NSError?) in
      guard let json = responseObject as? NSDictionary else {
        return
      }
      if (json[Constants.Api.ErrorKey] == nil) {
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "edit_points")
        NSUserDefaults.standardUserDefaults().synchronize()
        Session.updateOrCreateReunionPointsWithJson(json, ctx: self.dataLayer.managedObjectContext!)
        self.dataLayer.saveContext()
      }
    })
  }
  
  private func setupVolunteersAttendancePendingRequest() {
    guard let parameters = NSUserDefaults.standardUserDefaults().objectForKey("mark_assistance") as? NSDictionary else {
      return
    }
    SessionService.editVolunteersAttendance(parameters, completion: {(responseObject: AnyObject?, error: NSError?) in
      guard let json = responseObject as? NSDictionary else {
        return
      }
      if (json[Constants.Api.ErrorKey] == nil) {
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "mark_assistance")
        NSUserDefaults.standardUserDefaults().synchronize()
        Session.updateOrCreateVolunteersWithJson(json, ctx: self.dataLayer.managedObjectContext!)
        self.dataLayer.saveContext()
      }
    })
  }
  
}
