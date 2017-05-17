//
//  YouTubeLogIn.swift
//  Cover Tube
//
//  Created by June Suh on 5/12/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import AppAuth
import KeychainSwift


// MARK: OAuth2 constants
let keychain = KeychainSwift()

let reversedClientIDURL = URL(string: reversedClientID)

let iOSURL = URL(string: iOSURL_scheme)

let OAauth2_Auth_State_Key = "Oauth2AuthState"
let OAuth2_Refresh_Token_Key = "OAuth2RefreshToken"
let OAuth2_Access_Token_Key = "OAuth2AccessToken"

/* Checks whether user is logged in or not */
func isUserLoggedIn () -> Bool {
    if isAuthTokenActive() {
        if let authSTate = getAuthState() {
            return false
        }
        // return getAuthState()?.lastTokenResponse
    } else {
        return false
    }
    return false
}

/* Checks whether auth token expired or not. */
// TODO:
func isAuthTokenActive () -> Bool{
    if let authState = getAuthState() {
        if authState.lastTokenResponse == nil { return false }
        if authState.lastTokenResponse!.accessTokenExpirationDate == nil { return false }
        print("tokkk = \(authState.lastAuthorizationResponse.accessToken)")
        let accessTokenExpirationDate = authState.lastTokenResponse!.accessTokenExpirationDate!
        
        let now = Date()
        let remainingTime = now.timeIntervalSince(accessTokenExpirationDate)
        print("remainingTime = \(remainingTime)")
        if remainingTime < -5 * 60 {
            /* more than 5 minutes remaining */
            return true
        } else {
            return false
        }
    } else {
        // no authToken
        return false
    }
}

/* returns oauth2 token string if exists */
func getAuth2AccessTokenString () -> String? {
    return keychain.get(OAuth2_Access_Token_Key)
}

/* saves parameter string as OAuth2 string */
func saveAuth2Token (accessTokenString : String) {
    keychain.set(accessTokenString, forKey: OAuth2_Access_Token_Key)
}

/* updates root view controller based on logged in or not.
 Also sets the view controllers for the app delegate*/
func updateRootViewController ()
{
    let appDelegate = AppDelegate.getAppDelegate()
    if appDelegate == nil { return }
    if appDelegate!.window == nil { return }
    if appDelegate!.window! == nil { return }
    
    let window = appDelegate!.window!
    
    let currentRootVC = window.rootViewController
    
    if isUserLoggedIn()
    {
        if currentRootVC == nil {
            window.rootViewController = AppDelegate.getSnapchatSwipeContainerVC()
        } else if !(window.rootViewController is SwipeContainerViewController) {
            window.rootViewController = AppDelegate.getSnapchatSwipeContainerVC()
        } else {
            // already swipeContainerVC is root
        }
    }
    else // user is not logged in
    {
        if currentRootVC == nil {
            window.rootViewController = AppDelegate.getViewController()
        }
        else
        {
            if !(window.rootViewController! is ViewController) {
                window.rootViewController = AppDelegate.getViewController()
            }
            else {
                // already loginVC is root
            }
            
        }
    }
}

/*
 Logs into youtube
 https://developers.google.com/identity/protocols/OAuth2UserAgent
 Step 2. Redirect to Google's OAuth2 server
 Step 3. Google prompts user for consent
 */
func redirectToOAuth2Server ()
{
    let vc = AppDelegate.getViewController()
    if vc == nil { return }
    
    currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                      presenting: vc!,
                                                      callback: { (authState : OIDAuthState?,
                                                        error : Error?) in
                                                        /* Step 4: Handle the OAuth 2.0 server response */
                                                        
                                                        if authState != nil
                                                        {
                                                            handleRetrievedAuthState(authState: authState!)
                                                            validateToken()
                                                        }
                                                        else
                                                        {
                                                            print("login error : \(error!.localizedDescription)")
                                                            youTubeAuthState = nil
                                                        }
    })
}

let baseURLString = "https://www.googleapis.com/youtube/v3"
let likeURLString = "\(baseURLString)/videos/rate"

/* 
 Step 4: Handle the OAuth 2.0 server response
         if authState is not nil
 */
func handleRetrievedAuthState (authState : OIDAuthState)
{
    print("authState >> \(authState)")
    print("authState.lastTokenResponse = \(authState.lastTokenResponse)")
    let data = NSKeyedArchiver.archivedData(withRootObject: authState)
    keychain.set( data, forKey: OAauth2_Auth_State_Key )
    
    /* Store refresh token */
    if let refreshToken = authState.refreshToken
    {
        keychain.set(refreshToken, forKey: OAuth2_Refresh_Token_Key)
    }
    
    print("authState.lastTokenResponse = \(authState.lastTokenResponse)")
    
    print("got authroization. token = \(authState.lastTokenResponse?.accessToken)")
    let now = Date()
    let accessTokenExpirationDate = authState.lastTokenResponse!.accessTokenExpirationDate
    let timeInterval = now.timeIntervalSince(accessTokenExpirationDate!)
    print("see freshly retrieved token's time interval since now = \(timeInterval)")
    
    let youtubeToken = authState.lastTokenResponse!.accessToken!
    keychain.set(youtubeToken, forKey: OAuth2_Access_Token_Key)
    updateRootViewController()
    youTubeAuthState = authState
    
    authState.lastTokenResponse?.accessTokenExpirationDate
}

/* returns AuthState if previously retrieved successfully. */
func getAuthState() -> OIDAuthState? {
    let data = keychain.getData(OAauth2_Auth_State_Key)
    if data == nil { return nil }
    else {
        let authState = NSKeyedUnarchiver.unarchiveObject(with: data!) as! OIDAuthState
        print("decoded authState = \(authState)")
        return authState
    }
}


/*
 Likes the video using OAuth2 token
 */
func likeVideo (videoID : String)
{
    if keychain.get(OAuth2_Access_Token_Key) == nil {
        print("OAuth2TokenKey is empty")
        // MARK: Go to login view
        updateRootViewController()
        return
    }
    
    print("tok = \(keychain.get(OAuth2_Access_Token_Key))")
    let likeURLString = "https://www.googleapis.com/youtube/v3/videos/rate?id=\(videoID)&rating=like"
    let likeURL = URL(string: likeURLString)!
    var request = URLRequest(url: likeURL)
    request.httpMethod = "POST"
    
    
    // let paramString = "access_token=\(keychain.get(OAuth2_Access_Token_Key)!)"
    //    request.httpBody = paramString.data(using: .utf8)
    // request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
    request.addValue("Bearer \(keychain.get(OAuth2_Access_Token_Key)!)",
        forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request,
                                          completionHandler: { (data : Data?,
                                            response : URLResponse?, error : Error?) in
                                            if error == nil {
                                                let dataStr = String(data : data!, encoding : String.Encoding.utf8)
                                                print("dataString = \(dataStr)")
                                                validateToken()
                                            }
                                            else {
                                                print("likeVid error = \(error!.localizedDescription)")
                                            }
    })
    
    task.resume()
    
}


/* logs user out */
func logout() {
    keychain.delete(OAuth2_Access_Token_Key)
}

/*
 Validate user's token
 https://developers.google.com/identity/protocols/OAuth2UserAgent#handlingresponse
 Step 5: Validate the user's token
 */
func validateToken()
{
    let validateRequestURLString
        = "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=\(keychain.get(OAuth2_Access_Token_Key)!)"
    
    let validateRequestURL = URL(string: validateRequestURLString)!
    
    var request = URLRequest(url : validateRequestURL)
    request.httpMethod = "GET"
    
    let task = URLSession.shared.dataTask(with: request)
    { (data : Data?, urlResponse : URLResponse?, error : Error?) in
        if error == nil {
            let dataStr = String(data : data!,
                                 encoding : String.Encoding.utf8)
            
            print("val dataStr = \(String(describing: dataStr))")
        } else {
            print("validate : error = \(error?.localizedDescription)")
        }
    }
    task.resume()
}


/*
 Refresh token
 */
