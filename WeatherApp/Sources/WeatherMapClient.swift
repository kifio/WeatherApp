//
//  WeatherMapClient.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 06.10.2019.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit
import Alamofire

class WeatherMapClient: NSObject {
    
    private let appId: String = ""
    
    private struct OpenWeatherResponse: Codable {
        var cnt: Int
        var list: [OpenWeatherItem]
    }
    
     struct OpenWeatherWeather: Codable {
        var main: String
        var description: String
    }
    
    struct OpenWeatherTemperature: Codable {
        var temp: Double
        var pressure: Double
    }
    
    struct OpenWeatherInfo: Codable {
        var country: String
        var sunrise: Int64
        var sunset: Int64
    }
    
    struct OpenWeatherItem: Codable {
        var id: Int
        var name: String
        var weather: [OpenWeatherWeather]
        var main: OpenWeatherTemperature
        var sys: OpenWeatherInfo
    }
    
    struct OpenWeatherCity: Codable {
        var id: Int
        var name: String
        var country: String
    }
    
    private let baseUrl = "http://api.openweathermap.org/data/2.5"
    private let path = "/group?"
    private let params = "id=%s"
    private let decoder = JSONDecoder()
    private var cities: [OpenWeatherCity]!
    private var results: [OpenWeatherItem]!
    private var request: DataRequest? = nil
    
    override init() {
        super.init()
        initCitiesList()
    }

    private func initCitiesList() {
        let file = Bundle.main.path(forResource: "city.list", ofType: "json")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file!))
            cities = try self.decoder.decode([OpenWeatherCity].self, from: data)
        } catch {
            cities = [OpenWeatherCity]()
            print(error)
        }
        
        print("results count: \(cities.count)")
    }
    
    // Requect weather data for specific city, with known id
    func weather(id: String,
                 failure: @escaping (_ error: String) -> Void,
                 success: @escaping (_ response: [OpenWeatherItem]) -> Void) {
        makeRequest("id=\(id)", failure, success)
    }
    
    // Requect weather data for multiple cities, list of cities builds on the client side
    func weather(query: String,
                 failure: @escaping (_ error: String) -> Void,
                 success: @escaping (_ response: [OpenWeatherItem]) -> Void) {
        
        
        if self.request != nil {
            cancelLastRequest()
        }
        
        var filteredResults = [OpenWeatherCity]()
        
        self.cities
            .filter({(item: OpenWeatherCity) -> Bool in
                return item.name.lowercased().starts(with: query.lowercased())
            })
            .prefix(10)
            .forEach({ item in
                var isValid = true
                for city in filteredResults {
                    if item.name == city.name && item.country == city.country {
                        isValid = false
                    }
                }
                
                if isValid {
                    filteredResults.append(item)
                }
            })
        
        let ids = filteredResults
            .map({(item: OpenWeatherCity) -> String in
                return String(item.id)
            })
            .joined(separator: ",")
        
        makeRequest("id=\(ids)", failure, success)
    }
    
    private func makeRequest(_ id: String,
                             _ failure: @escaping (_ error: String) -> Void,
                             _ success: @escaping (_ response: [OpenWeatherItem]) -> Void) {
        let units = "&units=imperial"
        let appid = "&appId=\(self.appId)"
        let request = "\(baseUrl)\(path)\(id)\(units)\(appid)"
        //        print(request)
        self.request = AF.request(request)
        self.request?.response { response in
            if let data = response.data {
                let cities = self.parseItems(data)
                if cities.count == 0 {
                    failure("Cannot parce response for city \(id)")
                } else {
                    success(cities)
                }
            } else {
                failure(response.error?.errorDescription ?? "")
            }
        }
    }
    
    func cancelLastRequest() {
        self.request?.cancel()
        self.request = nil
    }
    
    private func parseItems(_ response: Data) -> [OpenWeatherItem] {
        do {
            let results = try self.decoder.decode(OpenWeatherResponse.self, from: response)
            return results.list
        } catch {
            print(error)
            return [OpenWeatherItem]()
        }
    }
}
