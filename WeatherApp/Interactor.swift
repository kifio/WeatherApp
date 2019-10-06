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
    
    struct Location : Codable {
        var city: String?
        var country: String?
    }
    
    struct Condition : Codable {
        var temperature: Float
    }
    
    struct CurrentObservation: Codable {
        var condition: Condition
    }
    
    struct City: Codable {
        
        var location: Location
        var current_observation: CurrentObservation?
        
        func getTemperature() -> Float? {
            return current_observation?.condition.temperature
        }
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
    private let weatherClient = WeatherClient()
    private let imagesClient = ImagesClient()
    
    func requestCitiesFromRemote(query: String,
                                 failure: @escaping (_ error: String) -> Void,
                                 success: @escaping (_ response: [City]) -> Void) {
        weatherClient.weather(location: query, failure: failure, success: { data in
            do {
                let city = try self.decoder.decode(City.self, from: data)
                success([city])
            } catch {
                //                print("Cannot decode content of OAuth.plist to OAuthKeys structure")
                print(String(decoding:data, as: UTF8.self))
                success([City]())
            }
        })
    }
    
    func loadImage(cityName: String,
                   failure: @escaping (_ error: String) -> Void,
                   success: @escaping (_ response: Data) -> Void) {
        
        imagesClient.requestUrbanArea(cityName: cityName, onFail: failure, onSuccess: { response in
            do {
                print(String(data: response, encoding: .utf8))
                let urbanArea = try self.decoder.decode(UrbanArea.self, from: response)
                self.downlodImage(data: urbanArea, failure: failure, success: success)
            } catch {
                failure("Cannot parse UrbanArea")
            }
        })
    }
    
    private func downlodImage(data: UrbanArea,
                              failure: @escaping (_ error: String) -> Void,
                              success: @escaping (_ response: Data) -> Void) {
        if data.photos.count > 0 {
            imagesClient.downloadImage(url: data.photos[0].image.web, onFail: failure, onSuccess: success)
        }
    }
    
    func saveSearchItemToCoreData(cityName: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "SearchItem", in: managedContext)!
        let searchItem = NSManagedObject(entity: entity, insertInto: managedContext)
        searchItem.setValue(cityName, forKeyPath: "city_name")
        searchItem.setValue(Date(), forKey: "timestamp")
        
        do {
            try managedContext.save()
        } catch {
            print("Could not save. \(cityName)")
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
                let location = Location(city: managedObject.value(forKey: "city_name") as? String, country: nil)
                let city = City(location: location, current_observation: nil)
                cities.append(city)
            }
            return cities
        } catch {
            print("Could not fetch.")
            return []
        }
    }
}
