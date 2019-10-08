//
//  CityCell.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 01.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class CityCell: UITableViewCell {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setTemperature(fahrenheits: Double) {
        if fahrenheits > 0 {
            weatherLabel.text = "\(fahrenheits)°F"
        } else {
            weatherLabel.text = ""
        }
    }
}
