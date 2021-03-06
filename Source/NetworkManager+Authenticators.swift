//
//  NetworkManager+Authenticators.swift
//  edX
//
//  Created by Christopher Lee on 5/13/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import SwiftyJSON
import edXCore

extension NetworkManager {
    
    public func addRefreshTokenAuthenticator(_ router:OEXRouter, session:OEXSession, clientId:String) {
        let invalidAccessAuthenticator = {[weak router] response, data in
            NetworkManager.invalidAccessAuthenticator(router, session: session, clientId:clientId, response: response, data: data)
        }
        self.authenticator = invalidAccessAuthenticator
    }
    
    /** Checks if the response's status code is 401. Then checks the error
     message for an expired access token. If so, a new network request to
     refresh the access token is made and this new access token is saved.
     */
    public static func invalidAccessAuthenticator(_ router: OEXRouter?, session:OEXSession, clientId:String, response: HTTPURLResponse?, data: Data?) -> AuthenticationAction {
        if let data = data,
            let response = response,
            let raw : AnyObject = try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions()) as AnyObject
        {
            let json = JSON(raw)
            
            guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
                let error = NSError(json: json, code: response.statusCode), statusCode == .code401Unauthorised else
            {
                return AuthenticationAction.proceed
            }
            
            guard let refreshToken = session.token?.refreshToken else {
                return logout(router)
            }
            
            if error.isAPIError(.OAuth2Expired) {
                return refreshAccessToken(clientId, refreshToken: refreshToken, session: session)
            }
            
            // This case should not happen on production. It is useful for devs
            // when switching between development environments.
            if error.isAPIError(.OAuth2Nonexistent) {
                return logout(router)
            }
        }
        Logger.logError("Network Authenticator", "Request failed: " + response.debugDescription)
        return AuthenticationAction.proceed
    }
}

private func logout(_ router:OEXRouter?) -> AuthenticationAction {
    DispatchQueue.main.async {
        router?.logout()
    }
    return AuthenticationAction.proceed
}

/** Creates a networkRequest to refresh the access_token. If successful, the
 new access token is saved and a successful AuthenticationAction is returned.
 */
private func refreshAccessToken(_ clientId:String, refreshToken:String, session: OEXSession) -> AuthenticationAction {
    return AuthenticationAction.authenticate({ (networkManager, completion) in
        let networkRequest = LoginAPI.requestTokenWith(
            refreshToken: refreshToken,
            clientId: clientId,
            grantType: "refresh_token"
        )
        networkManager.taskForRequest(networkRequest) {result in
            guard let currentUser = session.currentUser, let newAccessToken = result.data else {
                return completion(false)
            }
            session.save(newAccessToken, userDetails: currentUser)
            return completion(true)
        }
    })
}
