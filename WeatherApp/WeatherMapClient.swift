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
    
    private struct Coord: Codable {
        var lon: Double
        var lat: Double
    }
    
    private struct City: Codable {
        var id: Int
        var name: String
        var country: String
        var coord: Coord
    }
    
    private let baseUrl = "http://api.openweathermap.org/data/2.5"
    private let path = "/group?"
    private let params = "id=%s"
    private let decoder = JSONDecoder()
    private var credentials: OpenWeatherKeys!
    private var cities: [City]!
    private var request: DataRequest? = nil
    
    override init() {
        super.init()
        initAppId()
        initCities()
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
    
    private func initCities() {
        let file = Bundle.main.path(forResource: "city.list", ofType: "json")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file!))
            cities = try self.decoder.decode([City].self, from: data)
        } catch {
            cities = [City]()
            print("Cannot parse Cities list for OpenWeatherMap.")
        }
        
        print("Cities count: \(cities.count)")
    }
    
    func weather(query: String,
                    onFail: @escaping (_ error: String) -> Void,
                    onSuccess: @escaping (_ response: Data) -> Void) {
        
        let filteredCities = cities
            .filter({(item: City) -> Bool in
                return item.name.lowercased().starts(with: query.lowercased())
            })
            .map({(item: City) -> String in
                return String(item.id)
            })
        
        let ids = "id=\(filteredCities.prefix(5).joined(separator: ","))"
        let units = "&units=imperial"
        let appid = "&appId=\(self.credentials.appId)"
    
        let request = "\(baseUrl)\(path)\(ids)\(units)\(appid)"
        print(request)
        
        if self.request != nil {
            self.request?.cancel()
            self.request = nil
        }
        
        self.request = AF.request(request)
        self.request?.response { response in
            if let data = response.data {
                onSuccess(data)
            } else {
                onFail(response.error?.errorDescription ?? "")
            }
        }
    }
}
