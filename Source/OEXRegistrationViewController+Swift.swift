//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import SwiftyJSON

extension OEXRegistrationViewController {
    
    func getRegistrationFormDescription(_ success: (_ response: OEXRegistrationDescription) -> ()) {
        /*let networkManager = self.environment.networkManager
        let networkRequest = RegistrationFormAPI.registrationFormRequest()
        let result = OEXRegistrationDescription()*/
        if let path = Bundle.main.path(forResource: "registration_form", ofType: "json"),
            let data = try? NSData(contentsOfFile: path) as Data
        {
            let jsonData = JSON.init(data: data, options: JSONSerialization.ReadingOptions.allowFragments, error: nil)
            let regisData = jsonData.dictionaryObject.map{ OEXRegistrationDescription(dictionary: $0) }
            success(regisData!)
        }
        /*self.stream = networkManager.streamForRequest(networkRequest)
        (self.stream as! Stream<OEXRegistrationDescription>).listen(self) {[weak self] (result) in
            if let data = result.value {
                self?.loadController.state = .loaded
                success(response: data)
            }
            else{
                self?.loadController.state = LoadState.failed(result.error)
            }*/
        }
    
    //Testing only
    public var t_loaded : edXCore.Stream<()> {
        return (self.stream as! edXCore.Stream<OEXRegistrationDescription>).map {_ in () }
    }
    
}
