//
//  ProfileHelper.swift
//  edX
//
//  Created by Michael Katz on 9/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

open class ProfileAPI: NSObject {
    
    fileprivate static var currentUserFeed = [String: Feed<UserProfile>]()
    
    fileprivate static func profileDeserializer(_ response : HTTPURLResponse, json : JSON) -> Result<UserProfile> {
        return UserProfile(json: json).toResult()
    }

    fileprivate static func imageResponseDeserializer(_ response : HTTPURLResponse) -> Result<()> {
        return Success()
    }
    
    fileprivate class func path(_ username:String) -> String {
        return "/api/user/v1/accounts/{username}".oex_format(withParameters: ["username": username])
    }
    
    class func profileRequest(_ username: String) -> NetworkRequest<UserProfile> {
        return NetworkRequest(
            method: HTTPMethod.GET,
            path : path(username),
            requiresAuth : true,
            deserializer: .jsonResponse(profileDeserializer))
    }
    
    class func getProfile(_ username: String, networkManager: NetworkManager, handler: @escaping (_ profile: NetworkResult<UserProfile>) -> ()) {
        let request = profileRequest(username)
        _ = networkManager.taskForRequest(request, handler: handler)
    }

    class func getProfile(_ username: String, networkManager: NetworkManager) -> edXCore.Stream<UserProfile> {
        let request = profileRequest(username)
        return networkManager.streamForRequest(request)
    }

    class func profileUpdateRequest(_ profile: UserProfile) -> NetworkRequest<UserProfile> {
        let json = JSON(profile.updateDictionary)
        let request = NetworkRequest(method: HTTPMethod.PATCH,
            path: path(profile.username!),
            requiresAuth: true,
            body: RequestBody.jsonBody(json),
            headers: ["Content-Type": "application/merge-patch+json"], //should push this to a lower level once all our PATCHs support this content-type
            deserializer: .jsonResponse(profileDeserializer))
        return request
    }
    
    class func uploadProfilePhotoRequest(_ username: String, imageData: NSData) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_format(withParameters: ["username" : username])
        return NetworkRequest(method: HTTPMethod.POST,
            path: path,
            requiresAuth: true,
            body: RequestBody.dataBody(data: imageData as Data, contentType: "image/jpeg"),
            headers: ["Content-Disposition":"attachment;filename=filename.jpg"],
            deserializer: .noContent(imageResponseDeserializer))
    }
    
    class func deleteProfilePhotoRequest(_ username: String) -> NetworkRequest<()> {
        let path = "/api/user/v1/accounts/{username}/image".oex_format(withParameters: ["username" : username])
        return NetworkRequest(method: HTTPMethod.DELETE,
            path: path,
            requiresAuth: true,
            deserializer: .noContent(imageResponseDeserializer))
    }
}
