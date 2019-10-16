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
    
    struct DBConsts {
        fileprivate static let searchEntity = "SearchItem"
        fileprivate static let cityName = "city_name"
        fileprivate static let country = "country"
        fileprivate static let timestamp = "timestamp"
        fileprivate static let id = "id"
    }
    
    struct City: Codable {
        var id: String
        var temperature: Double = 0.0
        var name: String
        var country: String
        var main: String = ""
        var description: String = ""
        var pressure: Double = 0.0
        var sunrise: Int64 = 0
        var sunset: Int64 = 0
        var fromCache: Bool = false
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
    
    func requestCities(query: String,
                       failure: @escaping (_ error: String) -> Void,
                       success: @escaping (_ response: [City]) -> Void) {
        if let cities = getFromStorage(query) {
            success(cities)
        } else {
            weatherMapClient.weather(query: query, failure: failure, success: { response in
                let cities = response.map({(item: WeatherMapClient.OpenWeatherItem) -> Interactor.City in
                    return self.mapItemToCity(item)
                }) as [City]
                success(cities)
            })
        }
    }
    
    private func getFromStorage(_ query: String) -> [City]? {
        let cachedCities = getSavedSearchResults()
        for city in cachedCities {
            if city.name.lowercased().starts(with: query.lowercased()) {
                return [city]
            }
        }
        return nil
    }
    
    func requestCityById(id: String,
                         failure: @escaping (_ error: String) -> Void,
                         success: @escaping (_ response: City) -> Void) {
        weatherMapClient.weather(id: id, failure: failure, success: { response in
            let cities = response.map({(item: WeatherMapClient.OpenWeatherItem) -> Interactor.City in
                return self.mapItemToCity(item)
            }) as [City]
            if !cities.isEmpty {
                success(cities.first!)
            }
        })
    }

    private func mapItemToCity(_ item: WeatherMapClient.OpenWeatherItem) -> Interactor.City {
           return Interactor.City(
               id: String(item.id),
               temperature: item.main.temp,
               name: item.name,
               country: item.sys.country,
               main: item.weather[0].main,
               description: item.weather[0].description,
               pressure: item.main.pressure,
               sunrise: item.sys.sunrise,
               sunset: item.sys.sunset)
       }
    
    func loadImage(cityName: String,
                   w: Int, h: Int,
                   failure: @escaping (_ error: String) -> Void,
                   success: @escaping (_ response: Data) -> Void) {
        
        imagesClient.downloadImage(cityName: cityName, w: w, h: h, failure: failure, success: success)
    }
    
    func cancelLastRequest() {
        weatherMapClient.cancelLastRequest()
    }
    
    func saveSearchItemToCoreData(_ city: City) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: DBConsts.searchEntity, in: managedContext)!
        
        let searchItem = NSManagedObject(entity: entity, insertInto: managedContext)
        searchItem.setValue(city.name, forKeyPath: DBConsts.cityName)
        searchItem.setValue(city.country, forKeyPath: DBConsts.country)
        searchItem.setValue(city.id, forKeyPath: DBConsts.id)
        searchItem.setValue(Date(), forKey: DBConsts.timestamp)
        
        do {
            try managedContext.save()
        } catch {
            print("Could not save city. \(city.name)")
        }
    }
    
    func getSavedSearchResults() -> [City] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: DBConsts.searchEntity)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: DBConsts.timestamp, ascending: false)]
        
        do {
            var cities = [City]()
            let managedObjects = try managedContext.fetch(fetchRequest)
            for managedObject in managedObjects {
                let cityName = managedObject.value(forKey: DBConsts.cityName) as! String
                let country = managedObject.value(forKey: DBConsts.country) as! String
                let id = managedObject.value(forKey: DBConsts.id) as! String
                var city = City(id: id, name: cityName, country: country)
                city.fromCache = true
                cities.append(city)
            }
            return cities
        } catch {
            print("Could not fetch cities from storage.")
            return []
        }
    }
    
    func deleteSavedSearchResult(_ city: City) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DBConsts.searchEntity)
        fetchRequest.predicate = NSPredicate(format: "(id==%@)", city.id)
        
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

