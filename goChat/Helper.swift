//
//  Helper.swift
//  goChat
//
//  Created by hisham hawara on 2016-09-05.
//  Copyright © 2016 Hisham Hawara. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn
import FirebaseDatabase

class Helper {
    static let helper = Helper()
    func LoginAnonymously() {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (anonymousUser: FIRUser?, error: NSError?) in
            if error == nil {
                let newUser = FIRDatabase.database().reference().child("users").child("\(anonymousUser!.uid)")
                newUser.setValue(["displayName" : "anonymous", "id" : "\(anonymousUser!.uid)", "profileUrl" : ""])
                self.switchToNavigationViewController()
            } else {
                print(error?.localizedDescription)
                return
            }
        })
        
    }
    func LogInWithGoogle(authentication: GIDAuthentication){
    
    let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user: FIRUser?, error: NSError?) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            else{
                print(user?.email)
                print(user?.displayName)
                let newUser = FIRDatabase.database().reference().child("users").child("\(user!.uid)")
                newUser.setValue(["displayName" : "\(user!.displayName)", "id" : "\(user!.uid)", "profileUrl" : "\(user!.photoURL!)"])
                self.switchToNavigationViewController()
            }
        })
    
    }
    func switchToNavigationViewController(){
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyBoard.instantiateViewControllerWithIdentifier("NavigationVC") as! UINavigationController
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appdelegate.window?.rootViewController = naviVC
    
    }

    
}