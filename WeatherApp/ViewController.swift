//
//  ViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 28.09.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var citiesView: UITableView!
    
    let strings = ["Hello", "Darkness", "My", "Old", "Friend"];
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as? CityCell else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        cell.cityLabel.text = strings[indexPath.row]
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        citiesView.dataSource = self
        citiesView.delegate = self
    }
}

