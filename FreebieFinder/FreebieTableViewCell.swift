//
//  FreebieTableViewCell.swift
//  FreebieFinder
//
//  Created by Jonatious Joseph Jawahar on 10/16/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit

class FreebieTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbsUpCnt: UILabel!
    @IBOutlet weak var thumbsDownCnt: UILabel!
    @IBOutlet weak var TitleLbl: UILabel!
    @IBOutlet weak var PlaceLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
