//
//  User.swift
//  EducaApp
//
//  Created by Alonso on 9/2/15.
//  Copyright (c) 2015 Alonso. All rights reserved.
//

import Foundation
import CoreData

let UserEntityName = "User"
let UserIdKey = "id"
let UserNamesKey = "names"
let UserLastNameKey = "last_name"
let UserUsernameKey = "username"
let UserAuthTokenKey = "auth_token"
let UserLatitudeKey = "latitude"
let UserLongitudeKey = "longitude"
let UserProfilesKey = "profiles"
let UserActionsKey = "actions"
let UserReapplyKey = "can_reapply"
let UserPeriodKey = "period"
let UserPeriodNameKey = "name"
let UserPushEventsKey = "push_events"
let UserPushFeesKey = "push_fees"
let UserPushDocumentsKey = "push_documents"
let UserPushReportsKey = "push_reports"

@objc(User)
public class User: NSManagedObject {
  
  @NSManaged public var id: Int32
  @NSManaged public var firstName: String
  @NSManaged public var lastName: String
  @NSManaged public var username: String
  @NSManaged public var latitude: Float
  @NSManaged public var longitude: Float
  @NSManaged public var profiles: NSSet
  @NSManaged public var actions: NSSet
  @NSManaged public var canReapply: Bool
  @NSManaged public var periodId: Int32
  @NSManaged public var periodName: String
  @NSManaged public var pushEvents: Bool
  @NSManaged public var pushFees: Bool
  @NSManaged public var pushDocuments: Bool
  @NSManaged public var pushReports: Bool
  
  var fullName: String {
    let name = "\(firstName) \(lastName)"
    return name
  }
  
  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
  }
  
}

// MARK: - JSON Deserialization

extension User: Deserializable {
  
  func setDataFromJSON(json: NSDictionary) {
    if let id = json[UserIdKey] as AnyObject?, firstName = json[UserNamesKey] as? String, lastName = json[UserLastNameKey] as? String, username = json[UserUsernameKey] as? String {
      self.id = id is Int ? Int32(id as! Int) : Int32(id as! String)!
      self.firstName = firstName
      self.lastName = lastName
      self.username = username
      if let authToken = json[UserAuthTokenKey] as? String {
        if User.isSignedIn() == false {
          User.setAuthToken(authToken)
        }
      }
      if let latitude = json[UserLatitudeKey] as? Float, longitude = json[UserLongitudeKey] as? Float {
        self.latitude = latitude
        self.longitude = longitude
      }
      if let canReapply = json[UserReapplyKey] as? Bool, periodJson = json[UserPeriodKey] as? NSDictionary?, periodId = periodJson![UserIdKey] as AnyObject?, periodName = periodJson![UserPeriodNameKey] as? String  {
        if User.isSignedIn() == false {
          self.canReapply = canReapply
          self.periodId = periodId is Int ? Int32(periodId as! Int) : Int32(periodId as! String)!
          self.periodName = periodName
        }
      }
      if let pushEvents = json[UserPushEventsKey] as? Bool {
        self.pushEvents = pushEvents
      } else {
        self.pushEvents = false
      }
      
      if let pushDocuments = json[UserPushDocumentsKey] as? Bool {
        self.pushDocuments = pushDocuments
      } else {
        self.pushDocuments = false
      }
      
      if let pushFees = json[UserPushFeesKey] as? Bool {
        self.pushFees = pushFees
      } else {
        self.pushFees = false
      }
      
      if let pushReports = json[UserPushReportsKey] as? Bool {
        self.pushReports = pushReports
      } else {
        self.pushReports = false
      }
      
    }
  }
  
  func updateFavoriteArticle(article: Article, favorited: Bool, ctx: NSManagedObjectContext) {
    favorited ? (article.favoritedByCurrentUser = true) : (article.favoritedByCurrentUser = false)
  }
  
  func assistedToSession(session: Session, ctx: NSManagedObjectContext) -> Bool {
    return (SessionUser.findBySessionAndUser(session, user: self, ctx: ctx)?.attended)!
  }
  
  func markAttendanceToSession(session: Session, attended: Bool, ctx: NSManagedObjectContext) -> SessionUser {
    let sessionUser = SessionUser.findBySessionAndUser(session, user: self, ctx: ctx)
    sessionUser?.attended = attended
    return sessionUser!
  }
  
  func rateVolunteerInSession(session: Session, rating: Int, comment: String, ctx: NSManagedObjectContext) -> SessionUser {
    let sessionUser = SessionUser.findBySessionAndUser(session, user: self, ctx: ctx)
    sessionUser?.rating = Int32(rating)
    sessionUser?.comment = comment
    return sessionUser!
  }
  
  func hasPermissionWithId(id: Int) -> Bool {
    let actionsArray: NSArray = (self.actions.allObjects) as NSArray
    let actionsIds: Array<Int32> = actionsArray.map{(action) in return action.id} as Array<Int32>
    if actionsIds.contains(Int32(id)) {
      return true
    }
    return false
  }
  
  func isWebMaster() -> Bool {
    let profileIds = self.profiles.allObjects.map({ (profile) in
      return Int(profile.id)
    }) as NSArray
    return profileIds.containsObject(1) && !profileIds.containsObject(4)
  }
  
  func isOnlyGodfather() -> Bool {
    let profileIds = self.profiles.allObjects.map({ (profile) in
      return Int(profile.id)
    }) as NSArray
    return profileIds.containsObject(4) && profileIds.count == 1
  }
  
  func canListAssistantsComments() -> Bool {
    return self.hasPermissionWithId(33)
  }
  
  func canEditReunionPoints() -> Bool {
    return self.hasPermissionWithId(13)
  }
  
  func canCheckAttendance() -> Bool {
    return self.hasPermissionWithId(16)
  }
  
  func canSeeSchools() -> Bool {
    return self.hasPermissionWithId(28)
  }
  
}

// MARK: - CoreData

extension User {
  
  public class func syncWithJsonArray(arr: Array<NSDictionary>, ctx: NSManagedObjectContext) -> Array<User> {
    // Map JSON to ids, for easier access
    var jsonById = Dictionary<Int, NSDictionary>()
    for json in arr {
      if let id = json[UserIdKey] as AnyObject? {
        let usersId = id is Int ? id as! Int : Int(id as! String)!
        jsonById[usersId] = json
      }
    }
    let ids = Array(jsonById.keys)
    
    // Get persisted articles
    let persistedUsers = User.getAllUsers(ctx)
    var persistedUserById = Dictionary<Int, User>()
    for art in persistedUsers {
      persistedUserById[Int(art.id)] = art
    }
    let persistedIds = Array(persistedUserById.keys)
    
    // Create new objects for new ids
    let newIds = NSMutableSet(array: ids)
    newIds.minusSet(NSSet(array: persistedIds) as Set<NSObject>)
    let newUsers = newIds.allObjects.map({ (id: AnyObject) -> User in
      let newUser = NSEntityDescription.insertNewObjectForEntityForName(UserEntityName, inManagedObjectContext: ctx) as! User
      newUser.id = (Int32(id as! Int))
      return newUser
    })
    
    // Find existing objects
    let updateIds = NSMutableSet(array: ids)
    updateIds.intersectSet(NSSet(array: persistedIds) as Set<NSObject>)
    let updateUsers = updateIds.allObjects.map({ (id: AnyObject) -> User in
      return persistedUserById[id as! Int]!
    })
    
    // Apply json to each
    let validUsers = newUsers + updateUsers
    for user in validUsers {
      User.updateOrCreateWithJson(jsonById[Int(user.id)]!,ctx: ctx)
    }
    
    // Delete old items
    let deleteIds = NSMutableSet(array: persistedIds)
    deleteIds.minusSet(NSSet(array: ids) as Set<NSObject>)
    let deleteUsers = deleteIds.allObjects.map({ (id: AnyObject) -> User in
      return persistedUserById[id as! Int]!
    })
    for user in deleteUsers {
      if user.id != getAuthenticatedUser(ctx)?.id {
        ctx.deleteObject(user)
      }
    }
    
    return User.getAllUsers(ctx)
  }
  
  class func findOrCreateWithId(id: Int32, ctx: NSManagedObjectContext) -> User {
    var user: User? = getUserById(id, ctx: ctx)
    if (user == nil) {
      user = NSEntityDescription.insertNewObjectForEntityForName(UserEntityName, inManagedObjectContext: ctx) as? User
    }
    return user!
  }
  
  class func updateOrCreateWithJson(json: NSDictionary, ctx: NSManagedObjectContext) -> User? {
    var user: User?
    if let id = json[UserIdKey] as AnyObject?  {
      let userId = id is Int ? Int32(id as! Int) : Int32(id as! String)!
      user = findOrCreateWithId(userId, ctx: ctx)
      user?.setDataFromJSON(json)
    }
    if let profiles = json[UserProfilesKey] as? Array<NSDictionary> {
      Profile.syncJsonArrayWithUser(user!,arr: profiles, ctx: ctx)
    }
    if User.isSignedIn() == false {
      if let actions = json[UserActionsKey] as? Array<NSDictionary> {
        Action.syncJsonArrayWithUser(user!, arr: actions, ctx: ctx)
      }
    }
    return user
  }
  
  class func getAllUsers(ctx: NSManagedObjectContext) -> Array<User> {
    let fetchRequest = NSFetchRequest()
    fetchRequest.entity = NSEntityDescription.entityForName(UserEntityName, inManagedObjectContext: ctx)
    let sortDescriptor = NSSortDescriptor(key: "firstName", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    let users = try! ctx.executeFetchRequest(fetchRequest) as? Array<User>
    
    return users ?? Array<User>()
  }
  
  class func getUserById(id: Int32, ctx: NSManagedObjectContext) -> User? {
    let fetchRequest = NSFetchRequest()
    fetchRequest.entity = NSEntityDescription.entityForName(UserEntityName, inManagedObjectContext: ctx)
    fetchRequest.predicate = NSPredicate(format: "(id = %d)", Int(id))
    let users = try! ctx.executeFetchRequest(fetchRequest) as? Array<User>
    if (users != nil && users!.count > 0) {
      return users![0]
    }
    return nil
  }
  
  class func searchByName(searchText: String, ctx: NSManagedObjectContext) -> Array<User> {
    let fetchRequest = NSFetchRequest()
    fetchRequest.entity = NSEntityDescription.entityForName(UserEntityName, inManagedObjectContext: ctx)
    fetchRequest.predicate = NSPredicate(format: "firstName contains[cd] %@ OR lastName contains[cd] %@", searchText, searchText)
    let sortDescriptor = NSSortDescriptor(key: "firstName", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    let users = try! ctx.executeFetchRequest(fetchRequest) as? Array<User>
    
    return users ?? Array<User>()
  }
  
}

// MARK: - Authentication

extension User {
  
  class func getAuthenticatedUser(ctx: NSManagedObjectContext) -> User? {
    let defaults = NSUserDefaults.standardUserDefaults()
    if let id = defaults.integerForKey("authenticatedUserId") as Int? {
      let user = User.getUserById(Int32(id), ctx: ctx)
      return user
    }
    return nil
  }
  
  class func setAuthenticatedUser(user: User) {
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(Int(user.id), forKey: "authenticatedUserId")
    defaults.setBool(true, forKey: "signed_in")
    defaults.synchronize()
  }
  
  class func signOut(){
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setValue(nil, forKey: "authenticatedUserId")
    defaults.setBool(false, forKey: "signed_in")
    defaults.synchronize()
  }
  
  class func isSignedIn() -> Bool?  {
    let is_signed_in: AnyObject?  =  NSUserDefaults.standardUserDefaults().objectForKey("signed_in")
    return is_signed_in != nil && is_signed_in as! NSNumber == true
  }
  
}

// MARK: - KeychainWrapper

let keychainWrapper = KeychainWrapper()
  
extension User {
  
  class func setAuthToken(token: String) {
    keychainWrapper.mySetObject(token, forKey: kSecValueData)
    keychainWrapper.writeToKeychain()
  }
  
  class func getAuthToken() -> String {
    return keychainWrapper.myObjectForKey(Constants.Keychain.AuthTokenKey) as! String
  }
  
}
