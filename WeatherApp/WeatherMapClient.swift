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
    
    private struct OpenWeatherKeys: Codable {
        var appId: String
    }
    
    private struct OpenWeatherResponse: Codable {
        var cnt: Int
        var list: [OpenWeatherItem]
    }
    
    private struct OpenWeatherWeather: Codable {
        var main: String
        var description: String
    }
    
    private struct OpenWeatherTemperature: Codable {
        var temp: Double
        var pressure: Double
    }
    
    private struct OpenWeatherInfo: Codable {
        var country: String
        var sunrise: Int64
        var sunset: Int64
    }
    
    private struct OpenWeatherItem: Codable {
        var id: Int
        var name: String
        var weather: [OpenWeatherWeather]
        var main: OpenWeatherTemperature
        var sys: OpenWeatherInfo
    }
    
    private struct OpenWeatherCity: Codable {
        var id: Int
        var name: String
        var country: String
    }
    
    private let baseUrl = "http://api.openweathermap.org/data/2.5"
    private let path = "/group?"
    private let params = "id=%s"
    private let decoder = JSONDecoder()
    private var credentials: OpenWeatherKeys!
    private var cities: [OpenWeatherCity]!
    private var results: [OpenWeatherItem]!
    private var request: DataRequest? = nil
    
    override init() {
        super.init()
        initAppId()
        initCitiesList()
    }
    
    private func initAppId() {
        guard let path = Bundle.main.path(forResource: "OpenWeather", ofType: "plist") else {
            print("Path for OAuth.plist not defined")
            return
        }
        
        guard let keysFile = FileManager.default.contents(atPath: path) else {
            print("Cannot get content from OAuth.plist")
            return
        }
        
        do {
            credentials = try PropertyListDecoder().decode(OpenWeatherKeys.self, from: keysFile)
        } catch {
            print("Cannot decode content of OAuth.plist to OAuthKeys structure")
        }
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
    
    func weather(query: String,
                    onFail: @escaping (_ error: String) -> Void,
                    onSuccess: @escaping (_ response: [Interactor.City]) -> Void) {
              
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
        
        let id = "id=\(ids)"
        let units = "&units=imperial"
        let appid = "&appId=\(self.credentials.appId)"
    
        let request = "\(baseUrl)\(path)\(id)\(units)\(appid)"
        print(request)
        
        if self.request != nil {
            self.request?.cancel()
            self.request = nil
        }
        
        self.request = AF.request(request)
        self.request?.response { response in
            if let data = response.data {
                onSuccess(self.parseResponse(data))
            } else {
                onFail(response.error?.errorDescription ?? "")
            }
        }
    }
    
    private func parseResponse(_ response: Data) -> [Interactor.City] {
        do {
            let results = try self.decoder.decode(OpenWeatherResponse.self, from: response)
            return results.list.map({(item: OpenWeatherItem) -> Interactor.City in
                return Interactor.City(
                    temperature: item.main.temp,
                    name: item.name,
                    country: item.sys.country,
                    main: item.weather[0].main,
                    description: item.weather[0].description,
                    pressure: item.main.pressure,
                    sunrise: item.sys.sunrise,
                    sunset: item.sys.sunset)
            })
        } catch {
            print(error)
            return [Interactor.City]()
        }
    }
}
