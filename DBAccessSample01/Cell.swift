//
//  Cell.swift
//  DBAccessSample01
//
//  Created by guest on 2016/07/11.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit

class Cell: UITableViewCell {
    
    @IBOutlet weak var gnoLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
