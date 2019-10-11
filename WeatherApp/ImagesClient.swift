//
//  ImagesClient.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 04.10.19.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit
import Alamofire

class ImagesClient {
    
    private let baseUrl = "https://source.unsplash.com"

    func downloadImage(cityName: String,
                       w: Int, h: Int,
                       failure: @escaping (_ error: String) -> Void,
                       success: @escaping (_ response: Data) -> Void) {

        let resolution = "/\(w)x\(h)"
        let city = "/?\(cityName.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil))"

        AF.request("\(baseUrl)\(resolution)\(city)").response { response in
            if let data = response.data {
                success(data)
            } else {
                failure(response.error?.errorDescription ?? "")
            }
        }
    }
}
