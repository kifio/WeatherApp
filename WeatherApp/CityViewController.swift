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
 
    fileprivate var city: Interactor.City? = nil
    fileprivate var isRemovable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let cityName = self.city?.name {
                navigationBar.title = cityName
                appDelegate.getInteractor().loadImage(cityName: cityName, failure: { err in
                    print(err)
                }, success: { data in
                    let uiImage = UIImage(data: data)
                    self.imageView.contentMode = .scaleAspectFill;
                    self.imageView.clipsToBounds = true;
                    self.imageView.image = uiImage
                })
            }
        }
    }
    
    func setCity(_ city: Interactor.City) {
        self.city = city
    }

    func setRemoveOption(isRemovable: Bool) {

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
    
    private func authorizeUnsplash() {
        
    }

}
