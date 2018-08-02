//
//  FirebaseServices.swift
//  Flash Chat
//
//  Created by Adel on 8/1/18.
//  Copyright © 2018 London App Brewery. All rights reserved.
//

import Foundation
import Firebase

class FirebaseServices {

    private var channelRefHandle: DatabaseHandle?
    private lazy var channelRef: DatabaseReference = Database.database().reference()
    var users : [User] = []
    let userID = Auth.auth().currentUser!.uid
     var currentUserName = ""
    let channelsVC = ChannelListVC()

    // this function to get the UID from the email
    func getUserInfoFromEmail()
    {
        DispatchQueue.main.async {
            self.channelRefHandle = self.channelRef.child("Users").observe(.childAdded, with: { (snapshot) -> Void in // 1
                let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
                //let id = snapshot.key
                if let displayName = channelData["displayName"] as! String!,let userEmail = channelData["email"] as! String!,let userId = channelData["userId"] as! String!, displayName.characters.count > 0
                {
                    let newUser = User()
                    newUser.email = userEmail
                    newUser.displayName = displayName
                    newUser.UID = userId
                    //print(k"email:\(self.user.append(userr)")
                    self.users.append(newUser)
                    print("users \(newUser.displayName)")
                    if userId == self.userID {
                        self.currentUserName = displayName
                    }
                    DispatchQueue.main.async(execute: self.channelsVC.finishThread)
                }
                else {
                    print("Error! Could not decode channel data")
                }
            })
        }
        //print("ID\(user.UID)")
    }
   
}

