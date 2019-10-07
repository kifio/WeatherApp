//
//  ViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 28.09.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var citiesView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let weatherInteractor = Interactor()
    private var cities = [Interactor.City]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as? CityCell else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let city = cities[indexPath.row]
        cell.cityLabel.text = "\(city.name),\(city.country)"
        cell.setTemperature(fahrenheits: city.temperature)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let city = cities[indexPath.row]
        weatherInteractor.saveSearchItemToCoreData(cityName: city.name)

        let cityViewController = storyBoard.instantiateViewController(withIdentifier: "CityViewController") as! CityViewController
        cityViewController.setCity(city)
        self.present(cityViewController, animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("query: \(searchText)")
        if searchText.isEmpty {
            print("Query is empty")
            cities.removeAll()
            cities += weatherInteractor.getSavedSearchResults()
            self.citiesView.reloadData()
        } else {
            weatherInteractor.requestCitiesFromRemote(query: searchText, failure: { msg in
    //            let alertController = UIAlertController(title: "Alert", message: msg, preferredStyle: .alert)
    //            self.present(alertController, animated: true, completion: nil)
            }, success: { cities in
                self.cities.removeAll()
                self.cities += cities
                self.citiesView.reloadData()
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        citiesView.dataSource = self
        citiesView.delegate = self
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cities += weatherInteractor.getSavedSearchResults()
    }
}
