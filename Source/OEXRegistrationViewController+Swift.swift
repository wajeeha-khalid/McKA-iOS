//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXRegistrationViewController {
    
    func getRegistrationFormDescription(success: (response: OEXRegistrationDescription) -> ()) {
        /*let networkManager = self.environment.networkManager
        let networkRequest = RegistrationFormAPI.registrationFormRequest()
        let result = OEXRegistrationDescription()*/
        if let path = NSBundle.mainBundle().pathForResource("registration_form", ofType: "json")
        {
            let jsonData = JSON.init(data: NSData(contentsOfFile: path)!, options: NSJSONReadingOptions.AllowFragments, error: nil)
            let regisData = jsonData.dictionaryObject.map{ OEXRegistrationDescription(dictionary: $0) }
            success(response: regisData!)
        }
        /*self.stream = networkManager.streamForRequest(networkRequest)
        (self.stream as! Stream<OEXRegistrationDescription>).listen(self) {[weak self] (result) in
            if let data = result.value {
                self?.loadController.state = .Loaded
                success(response: data)
            }
            else{
                self?.loadController.state = LoadState.failed(result.error)
            }*/
        }
    
    //Testing only
    public var t_loaded : Stream<()> {
        return (self.stream as! Stream<OEXRegistrationDescription>).map {_ in () }
    }
    
}
