//
//  LocationTableViewCell.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 28/8/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var locationImage: UIImageView!
    
    @IBOutlet weak var locationNameLabel: UILabel!
    
    @IBOutlet weak var locationDescriptionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
