//
//  WeatherInteractor.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 02.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Interactor {
    
    struct City: Codable {
        var temperature: Double = 0.0
        var name: String
        var country: String
        var main: String = ""
        var description: String = ""
        var pressure: Double = 0.0
        var sunrise: Int64 = 0
        var sunset: Int64 = 0
    }
    
    struct Image: Codable {
        var web: String
    }
    
    struct Photo: Codable {
        var image: Image
    }
    
    struct UrbanArea: Codable {
        var photos: [Photo]
    }
    
    private let decoder = JSONDecoder()
    private let weatherMapClient = WeatherMapClient()
    private let imagesClient = ImagesClient()
    
    func requestCitiesFromRemote(query: String,
                                 failure: @escaping (_ error: String) -> Void,
                                 success: @escaping (_ response: [City]) -> Void) {
        let cachedCities = getSavedSearchResults()
        for city in cachedCities {
            if city.name.lowercased().starts(with: query.lowercased()) {
                success([city])
                return
            }
        }
        weatherMapClient.weather(query: query, onFail: failure, onSuccess: success)
    }
    
    func loadImage(cityName: String,
                   w: Int, h: Int,
                   failure: @escaping (_ error: String) -> Void,
                   success: @escaping (_ response: Data) -> Void) {
        
        imagesClient.downloadImage(cityName: cityName, w: w, h: h, failure: failure, success: success)
    }

    
    func saveSearchItemToCoreData(_ city: City) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "SearchItem", in: managedContext)!
        
        let searchItem = NSManagedObject(entity: entity, insertInto: managedContext)
        searchItem.setValue(city.name, forKeyPath: "city_name")
        searchItem.setValue(city.country, forKeyPath: "country")
        searchItem.setValue(Date(), forKey: "timestamp")
        
        do {
            try managedContext.save()
        } catch {
            print("Could not save. \(city.name)")
        }
    }
    
    func getSavedSearchResults() -> [City] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SearchItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            var cities = [City]()
            let managedObjects = try managedContext.fetch(fetchRequest)
            for managedObject in managedObjects {
                let cityName = managedObject.value(forKey: "city_name") as! String
                let country = managedObject.value(forKey: "country") as! String
                let city = City(name: cityName, country: country)
                cities.append(city)
            }
            return cities
        } catch {
            print("Could not fetch.")
            return []
        }
    }
    
    func deleteSavedSearchResult(_ city: City) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SearchItem")
        fetchRequest.predicate = NSPredicate(format: "(city_name==%@) AND (country==%@)", city.name, city.country)
        
        do {
            let managedObjects = try managedContext.fetch(fetchRequest)
            for managedObject in managedObjects {
                if let o = managedObject as? NSManagedObject {
                    managedContext.delete(o)
                    do {
                        try managedContext.save()
                    } catch {
                        print(error)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
}

