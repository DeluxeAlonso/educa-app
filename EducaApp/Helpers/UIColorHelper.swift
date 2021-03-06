//
//  UIColorHelper.swift
//  EducaApp
//
//  Created by Alonso on 9/4/15.
//  Copyright (c) 2015 Alonso. All rights reserved.
//

import Foundation

extension UIColor {
  
  class func colorWithR(r: Int, green g:Int, blue b: Int, alpha a:Float) -> UIColor {
    return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
  }
  
  class func defaultTextColor() -> UIColor {
    return UIColor.colorWithR(0, green: 153, blue: 204, alpha: 1)
  }
  
  class func defaultSmallTextColor() -> UIColor {
    return UIColor.colorWithR(96, green: 185, blue: 214, alpha: 1)
  }
  
  class func defaultBackgroundColor() -> UIColor {
    return UIColor.colorWithR(240, green: 255, blue: 255, alpha: 1)
  }
  
  class func defaultBorderFieldColor() -> UIColor {
    return UIColor.colorWithR(193, green: 193, blue: 193, alpha: 1)
  }
  
  class func defaultBlackBorderFieldColor() -> UIColor {
    return UIColor.blackColor()
  }
  
  class func defaultRefreshControlColor() -> UIColor {
    return UIColor.colorWithR(236, green: 240, blue: 241, alpha: 1)
  }
  
  class func defaultHappyFaceBorderColor() -> UIColor {
    return UIColor.colorWithR(241, green: 196, blue: 14, alpha: 1)
  }
  
  class func defaultSadFaceBorderColor() -> UIColor {
    return UIColor.colorWithR(231, green: 76, blue: 60, alpha: 1)
  }
  
  class func defaultFilterBorderField() -> UIColor {
    return UIColor.colorWithR(199, green: 199, blue: 204, alpha: 1)
  }
  
  class func defaultDocumentPreviewNavColor() -> UIColor {
    return UIColor.colorWithR(0, green: 0, blue: 0, alpha: 0.5)
  }
  
}
