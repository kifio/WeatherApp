//
//  AuthorizationWebViewViewController.swift
//  WeatherApp
//
//  Created by Ivan Murashov on 11.10.2019.
//  Copyright © 2019 kifio. All rights reserved.
//

import UIKit

class AuthorizationWebViewViewController: ViewController {

    private struct UnsplashCredentials {
        var accessKey: String
        var secretKey: String
    }
    
    private var credentials: UnsplashCredentials!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUnsplashKeys()
        
        
        // loading URL :
        let urlString = "https://unsplash.com/oauth/authorize?client_id=\(credentials.accessKey)&redirect_uri=kWeather://foo.org&scope=public&response_type=code"
        let url = URL(string: urlString)
        let request = URLRequest(URL: url!)
        // init and load request in webview.
        webView = WKWebView(frame: self.view.frame)
        webView.navigationDelegate = self
        webView.loadRequest(request)
        self.view.addSubview(webView)
        self.view.sendSubviewToBack(webView)
    }
    

    private func initUnsplashKeys() {
        guard let path = Bundle.main.path(forResource: "Unsplash", ofType: "plist") else {
            print("Path for OAuth.plist not defined")
            return
        }
        
        guard let keysFile = FileManager.default.contents(atPath: path) else {
            print("Cannot get content from Unsplash.plist")
            return
        }
        
        do {
            credentials = try PropertyListDecoder().decode(UnsplashCredentials.self, from: keysFile)
        } catch {
            print("Cannot decode content of Unsplash.plist to UnsplashCredentioals structure")
        }
    }

}
