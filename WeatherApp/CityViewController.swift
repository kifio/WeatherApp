//
//  CityViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 02.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit
import WebKit

class CityViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    @IBOutlet weak var overlay: UIView!
    
    fileprivate var city: Interactor.City? = nil
    fileprivate var isRemovable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let city = self.city {
                
                if city.fromCache {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.getInteractor().requestCityById(id: city.id, failure: {_ in
                            print("Cannot load weather for city \(city.id)")
                        }, success: { resp in
                            self.setCity(resp)
                            self.updateLabels(resp)
                        })
                    }
                } else {
                    updateLabels(city)
                }
                
                
                navigationBar.title = city.name
                let w = Int(self.view.frame.width)
                let h = Int(self.view.frame.height)

                appDelegate.getInteractor().loadImage(cityName: city.name, w: w, h: h, failure: { err in
                    print(err)
                }, success: { data in
                    let uiImage = UIImage(data: data)
                    self.imageView.contentMode = .scaleAspectFill;
                    self.imageView.clipsToBounds = true;
                    self.imageView.image = uiImage
                })

                self.overlay.layer.opacity = 0.3
            }
        }
    }
    
    private func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }
    
    func setCity(_ city: Interactor.City) {
        self.city = city
    }
    
    private func updateLabels(_ city: Interactor.City) {
        self.city = city
        self.cityLabel.text = "\(city.name), \(city.country)"
        self.temperatureLabel.text = "\(city.temperature)°F"
        self.descriptionLabel.text = city.description
        
        let dateFormatter = getDateFormatter()
        self.sunriseLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(city.sunrise)))
        self.sunsetLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(city.sunset)))
    }

    func setRemoveOption(isRemovable: Bool) {
        self.isRemovable = isRemovable
        if !self.isRemovable {
            navigationBar.leftBarButtonItem = nil
        }
    }
    
    @IBAction func closeViewController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func deleteSearchItem(_ sender: Any) {
        let alertController = UIAlertController(title: "Alert",
            message: "City will be deleted.\n Operation cannot be undone.", 
            preferredStyle: .alert)

        let actionYes = UIAlertAction(title: "Just Do it!",
            style: .destructive,
            handler: { action in
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    if let city = self.city {
                        appDelegate.getInteractor().deleteSavedSearchResult(city)
                    }

                    if let presenter = self.presentingViewController as? ViewController {
                        presenter.updateTableView(appDelegate.getInteractor().getSavedSearchResults())
                    }

                    self.dismiss(animated: true, completion: nil)
                }
            })

        alertController.addAction(actionYes)
        self.present(alertController, animated: true, completion: nil)
    }

}
