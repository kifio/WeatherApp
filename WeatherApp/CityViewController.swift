//
//  CityViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 02.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class CityViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
 
    private let interactor = Interactor()
    private var city: Interactor.City? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.title = self.city?.location.city
        interactor.loadImage(cityName: (self.city?.location.city!)!, failure: { err in
            print(err)
        }, success: { data in
            let uiImage = UIImage(data: data)
            self.imageView.contentMode = .scaleAspectFill;
            self.imageView.clipsToBounds = true;
            self.imageView.image = uiImage
        })
    }
    
    func setCity(_ city: Interactor.City) {
        self.city = city
    }
    
    @IBAction func deleteSearchitem(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
