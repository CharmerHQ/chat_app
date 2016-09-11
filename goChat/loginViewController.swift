//
//  loginViewController.swift
//  goChat
//
//  Created by hisham hawara on 2016-09-04.
//  Copyright © 2016 Hisham Hawara. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class loginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    @IBOutlet weak var anonymousButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        anonymousButton.layer.borderWidth = 2.0
        anonymousButton.layer.borderColor = UIColor.whiteColor().CGColor
        GIDSignIn.sharedInstance().clientID = "902592514369-hbnmof7vsr5tcsmvf4qgk8s3le5nkjut.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth: FIRAuth, user: FIRUser?) in
            if user != nil {
                Helper.helper.switchToNavigationViewController()
            }
            else {
                print("unauth")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func LoginAnonymouslyDidTapped(sender: AnyObject) {

        Helper.helper.LoginAnonymously()
    }

    @IBAction func googleLoginDidTapped(sender: AnyObject) {
        GIDSignIn.sharedInstance().signIn()
        
    }
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if error != nil {
            print(error.localizedDescription)
        }
        Helper.helper.LogInWithGoogle(user.authentication)

    }

}
