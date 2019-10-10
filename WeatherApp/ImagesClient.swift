//
//  ImagesClient.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 04.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit
import UnsplashPhotoPicker

class ImagesClient {

    init() {
        UnsplashPhotoPicker()
    }
    
    struct Image: Codable {
        var mobile: String
    }
    
    struct Photo: Codable {
        var image: Image
    }
    
    struct UrbanArea: Codable {
        var photos: [Photo]
    }
    
    private let baseUrl = "https://api.teleport.org/api/urban_areas/slug:"
    
    func requestUrbanArea(cityName: String,
                         onFail: @escaping (_ error: String) -> Void,
                         onSuccess: @escaping (_ response: Data) -> Void) {
        
        let stringUrl = baseUrl + cityName.lowercased() + "/images/"
        print(stringUrl)
        
        AF.request(stringUrl).response { response in
            if let data = response.data {
                onSuccess(data)
            } else {
                onFail(response.error?.errorDescription ?? "")
            }
        }
    }
    
    func downloadImage(url: String,
                       onFail: @escaping (_ error: String) -> Void,
                       onSuccess: @escaping (_ response: Data) -> Void) {
        AF.request(url).response { response in
            if let data = response.data {
                onSuccess(data)
            } else {
                onFail(response.error?.errorDescription ?? "")
            }
        }
    }
}
