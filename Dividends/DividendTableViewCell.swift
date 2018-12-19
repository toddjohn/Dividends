//
//  DividendTableViewCell.swift
//  Dividends
//
//  Created by Todd Johnson on 12/19/18.
//  Copyright © 2018 Todd Johnson. All rights reserved.
//

import UIKit

class DividendTableViewCell: UITableViewCell {

    @IBOutlet weak var symbolLabel: UILabel?
    @IBOutlet weak var nameLabel: UILabel?
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
