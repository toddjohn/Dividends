//
//  DividendHistoryTableViewCell.swift
//  Dividends
//
//  Created by Todd Johnson on 4/28/19.
//  Copyright © 2019 Todd Johnson. All rights reserved.
//

import UIKit

class DividendHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var dividendLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
