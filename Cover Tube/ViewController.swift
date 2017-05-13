//
//  ViewController.swift
//  Cover Tube
//
//  Created by June Suh on 3/2/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit
import AppAuth

/*
 https://github.com/openid/AppAuth-iOS
 */
var currentAuthorizationFlow : OIDAuthorizationFlowSession? = nil
var youTubeAuthState : OIDAuthState? = nil
let oauthURL = URL(string: "\(iOSURL_scheme):/oauth/callback")!

let request = OIDAuthorizationRequest(configuration: configuration,
                                      clientId: clientID,
                                      clientSecret: nil,
                                      scopes: [OIDScopeOpenID, OIDScopeProfile],
                                      redirectURL: oauthURL,
                                      responseType: OIDResponseTypeCode,
                                      additionalParameters: nil)

class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton)
    {
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                          presenting: self,
                                                          callback: { (authState : OIDAuthState?,
                                                            error : Error?) in
                                                            if authState != nil
                                                            {
                                                                print("got authroization. token = \(authState?.lastTokenResponse?.accessToken)")
                                                                youTubeAuthState = authState
                                                            } else {
                                                                print("login error : \(error!.localizedDescription)")
                                                                youTubeAuthState = nil
                                                            }
        })
    }
    
    
    
}

