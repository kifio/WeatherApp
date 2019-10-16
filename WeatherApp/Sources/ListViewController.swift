//
//  ViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 28.09.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var citiesView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var cities = [Interactor.City]()
    private let transition = PopAnimator()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as? CityCellView else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let city = cities[indexPath.row]
        cell.cityLabel.text = "\(city.name),\(city.country)"
        cell.setTemperature(fahrenheits: city.temperature)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let city = cities[indexPath.row]
            appDelegate.getInteractor().deleteSavedSearchResult(city)
            appDelegate.getInteractor().saveSearchItemToCoreData(city)
            self.performSegue(withIdentifier: "showCity", sender: city)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cityViewController = segue.destination as? CityViewController {
            if let city = sender as? Interactor.City {
                cityViewController.setCity(city)
            }
            cityViewController.transitioningDelegate = self
            cityViewController.modalPresentationStyle = .fullScreen
            cityViewController.completion = {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    if self.searchBar.searchTextField.text?.isEmpty ?? false {
                        self.updateTableView(appDelegate.getInteractor().getSavedSearchResults())
                    }
                }
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            print("query: \(searchText)")
            if searchText.isEmpty {
                print("Query is empty")
                appDelegate.getInteractor().cancelLastRequest()
                self.updateTableView(appDelegate.getInteractor().getSavedSearchResults())
            } else {
                appDelegate.getInteractor().requestCities(query: searchText, failure: { msg in
                    print(msg)
                }, success: { cities in
                    self.updateTableView(cities)
                })
            }
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
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            cities += appDelegate.getInteractor().getSavedSearchResults()
        }
    }
    
    func updateTableView(_ cities: [Interactor.City]) {
        self.cities.removeAll()
        self.cities += cities
        self.citiesView.reloadData()
    }
}

extension ListViewController : UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if let selectedIndexPathCell = self.citiesView.indexPathForSelectedRow,
            let selectedCell = self.citiesView.cellForRow(at: selectedIndexPathCell) as? CityCellView,
            let selectedCellSuperview = selectedCell.superview {
            transition.originFrame = selectedCellSuperview.convert(selectedCell.frame, to: nil)
            transition.originFrame = CGRect(
                x: transition.originFrame.origin.x + 20,
                y: transition.originFrame.origin.y + 20,
                width: transition.originFrame.size.width - 40,
                height: transition.originFrame.size.height - 40
            )
        }

        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

}
