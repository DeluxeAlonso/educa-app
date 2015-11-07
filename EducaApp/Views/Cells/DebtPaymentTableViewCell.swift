//
//  DebtPaymentTableViewCell.swift
//  EducaApp
//
//  Created by Alonso on 11/6/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

class DebtPaymentTableViewCell: UITableViewCell {
  
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func setupPayment(payment: Payment) {
    amountLabel.text = "\(payment.amount)"
    statusLabel.text = "Vencido"
    let date = payment.dueDate
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "dd/MM/Y"
    let dateString = dateFormatter.stringFromDate(date)
    dateLabel.text = dateString
  }
  
}
