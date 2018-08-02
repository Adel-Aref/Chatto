//
//  ChannelListVC.swift
//  Flash Chat
//
//  Created by Adel on 7/30/18.
//  Copyright © 2018 London App Brewery. All rights reserved.
//
import UIKit
import Firebase
import FirebaseDatabase
class User {
    var displayName:String = ""
    var email:String = ""
    var UID:String = ""
}
class ChannelListVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    let userID = Auth.auth().currentUser!.uid
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtEmail: UITextField!
    var senderDisplayName: String? // 1
    var newChannelTextField: UITextField? // 2
    var arrayOfchannels: [Channel] = [] // 3
    var arrayOfUserChannels: [Channel] = []
    var adminChannel: [Channel] = []
    var users : [User] = []
    var currentUserName = ""
    var myIndexPath = IndexPath()
    //var firebaseService = FirebaseServices()
    private lazy var channelRef: DatabaseReference = Database.database().reference()
    private var channelRefHandle: DatabaseHandle?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 44
        getUserInfoFromEmail()
        observeUserChannels()
        
    }
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let channel = sender as? Channel {
            let chatVc = segue.destination as! ChatViewController
    
            chatVc.senderDisplayName = ""
            
            chatVc.channel = channel
            chatVc.channelRef = channelRef.child(channel.fromId)
            chatVc.myIndexPath = myIndexPath
            chatVc.users = users
            chatVc.currentUserName = currentUserName
            print(" ChatVc : \(chatVc.myIndexPath)")
        }
    }
    // this function create a chanel
    func createChannel(indexPath:IndexPath){
        self.channelRef.child("channels").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.hasChild((Auth.auth().currentUser?.uid)!){
                
                print("true rooms exist")
                  }
            else{
                
                print("false room doesn't exist")
                //self.users[indexPath.row].UID != "718CvCRMXmd0NPzholMG1lEZ4d62" &&
                if  self.userID == "718CvCRMXmd0NPzholMG1lEZ4d62"
                {
                    let newChannelRef = self.channelRef.child("channels").child(self.users[indexPath.row].UID) //
                    let channelItem = [
                        "fromUID":Auth.auth().currentUser?.uid,
                        "fromName":self.currentUserName,
                        "toName":self.users[indexPath.row].displayName,
                        "ToUID":self.users[indexPath.row].UID
                    ]
                    newChannelRef.setValue(channelItem)
                }
                if  self.userID != "718CvCRMXmd0NPzholMG1lEZ4d62"{
                    let newChannelRef = self.channelRef.child("channels").child(self.userID) //
                    let channelItem = [
                        "fromUID":Auth.auth().currentUser?.uid,
                        "fromName":self.currentUserName,
                        "toName":self.users[indexPath.row].displayName,
                        "ToUID":self.users[indexPath.row].UID
                    ]
                    newChannelRef.setValue(channelItem)
                }
                
            }
        })
    }
    
    private func observeUserChannels() {
//      DispatchQueue.main.async {
//        let userID = Auth.auth().currentUser!.uid
//        self.channelRefHandle = self.channelRef.child("channels").observe(.childAdded, with: { (snapshot) -> Void in // 1
//            let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
//            let id = snapshot.key
//            if let name = channelData["displayName"] as! String!, name.characters.count > 0 {
//                self.arrayOfchannels.append(Channel(id: id, name: name, Tid: <#String#>))
//                    self.tableView.reloadData()
//                     DispatchQueue.main.async(execute: self.finishThread)
//            } else {
//                print("Error! Could not decode channel data")
//            }
//        })
//        }
    }
    // this function to get the UID from the email
    func getUserInfoFromEmail()
    {
        DispatchQueue.main.async {
            
                        self.channelRefHandle = self.channelRef.child("Users").observe(.childAdded, with: { (snapshot) -> Void in // 1
                let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
                //let id = snapshot.key
                if let displayName = channelData["displayName"] as! String!,let userEmail = channelData["email"] as! String!,let userId = channelData["userId"] as! String!, displayName.characters.count > 0
                {
                    if userId != "718CvCRMXmd0NPzholMG1lEZ4d62" && self.userID == "718CvCRMXmd0NPzholMG1lEZ4d62"{
                    let newUser = User()
                    newUser.email = userEmail
                    newUser.displayName = displayName
                    newUser.UID = userId
                    //print(k"email:\(self.user.append(userr)")
                    self.users.append(newUser)
                        print("users \(newUser.displayName)")
                    }
                    if userId == "718CvCRMXmd0NPzholMG1lEZ4d62" && self.userID != "718CvCRMXmd0NPzholMG1lEZ4d62"{
                        let newUser = User()
                        newUser.email = userEmail
                        newUser.displayName = displayName
                        newUser.UID = userId
                        //print(k"email:\(self.user.append(userr)")
                        self.users.append(newUser)
                        print("users \(newUser.displayName)")
                    }
                    if userId == self.userID {
                        self.currentUserName = displayName
                    }
                    DispatchQueue.main.async(execute: self.finishThread)
                }
                else {
                    print("Error! Could not decode channel data")
                }
            })
        }
        //print("ID\(user.UID)")
    }
    func finishThread(){
        
        tableView.reloadData()

    }
    @IBAction func addPersonRoomPressed(_ sender: UIBarButtonItem) {
        
    }
    // End of the class
}

// Extenion of ChanellListViewController
extension ChannelListVC
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return users.count

    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell")
            as? ChannelCell else {return UITableViewCell()}
        
        let user = users[indexPath.row]
        cell.lblChannelTitle.text = user.displayName
        //cell.lblChannelTitle.tag = indexPath.row
        print("the display name is \(user.displayName)")
        return cell
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = Channel(Fid: userID, Fname: currentUserName, Tid:users[indexPath.row].UID, Tname: users[indexPath.row].displayName)
        myIndexPath = indexPath
        createChannel(indexPath:indexPath)
        self.performSegue(withIdentifier: "ShowChannel", sender: channel)
    }
    
    // end of the class
}
