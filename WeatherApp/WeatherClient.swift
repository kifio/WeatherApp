//
//  WeatherClient.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 01.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit
import OAuthSwift

fileprivate struct OAuthKeys: Codable {
    var appId: String
    var clientId: String
    var clientSecret: String
}

class WeatherClient {
    
    private static let ResponseType = "json"
    private static let UnitType = "c"
    
    private var currentRequests: [OAuthSwiftRequestHandle?] = []
    
    private let url:String = "https://weather-ydn-yql.media.yahoo.com/forecastrss"
    private var oauth:OAuth1Swift? = nil
    private var headers = [String:String]()
    
    init() {
        
        guard let path = Bundle.main.path(forResource: "OAuth", ofType: "plist") else {
            print("Path for OAuth.plist not defined")
            return
        }
        
        guard let keysFile = FileManager.default.contents(atPath: path) else {
            print("Cannot get content from OAuth.plist")
            return
        }
        
        do {
            let credentials = try PropertyListDecoder().decode(OAuthKeys.self, from: keysFile)
            self.headers["X-Yahoo-App-Id"] = credentials.appId
            self.oauth = OAuth1Swift(consumerKey: credentials.clientId, consumerSecret: credentials.clientSecret)
        } catch {
            print("Cannot decode content of OAuth.plist to OAuthKeys structure")
        }
    }
    
    public func weather(location:String,
                        failure: @escaping (_ error: String) -> Void,
                        success: @escaping (_ response: Data) -> Void) {
        let params = ["location":location, "format":WeatherClient.ResponseType, "u":WeatherClient.UnitType]
        self.makeRequest(parameters: params, completionHandler: { result in
            self.currentRequests = []
            switch result {
                case .success(let response):
                    print("Get result for: \(location)")
                    success(response.data)
                case .failure(let error):
                    failure(error.description)
            }
        })
    }
    
    private func makeRequest(parameters:[String:String],
                             completionHandler: @escaping OAuthSwiftHTTPRequest.CompletionHandler) {
        
        if let activeRequest = self.currentRequests.last as? OAuthSwiftHTTPRequest {
            print("Current requests: \(self.currentRequests.count), Cancelled Request: \(activeRequest.config.parameters)")
            self.currentRequests.forEach({ $0?.cancel() })
            self.currentRequests = []
        }
        let request = self.oauth?.client.request(self.url, method: .GET,
            parameters: parameters,
            headers: self.headers,
            body: nil,
            checkTokenExpiration: false,
            completionHandler: completionHandler)
        self.currentRequests.append(request)
        
    }
}
