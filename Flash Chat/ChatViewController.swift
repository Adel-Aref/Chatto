//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
import FirebaseDatabase
import JSQMessagesViewController
import Photos
import FirebaseStorage

class ChatViewController: JSQMessagesViewController,UITextFieldDelegate {
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    // MARK: Properties
    var myIndexPath = IndexPath()
    var users:[User] = []
    var currentUserName = ""
    var arrayOfchannels:[String] = []
    let userID = Auth.auth().currentUser!.uid
    
    var messages = [JSQMessage]()
    var channelRef: DatabaseReference?
    var messagesRef: DatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.fromName
        }
    }
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    private lazy var messageRef: DatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: DatabaseHandle?
     private var channelRefHandle: DatabaseHandle?
    private lazy var usersTypingQuery: DatabaseQuery =
        self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://chatoo-7b42a.appspot.com")
    private var updatedMessageRefHandle: DatabaseHandle?
    
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    // MARK: View Lifecycle
    private let imageURLNotSetKey = "NOTSET"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = Auth.auth().currentUser?.uid
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        observeMessages()
        observChannels()
        
        //print("Name : \(Auth.auth().currentUser!.displayName) ID : \(Auth.auth().currentUser?.uid)")
        print("index :\(myIndexPath)")
        print("messgaassaaa :\(messages.count)")
        //TODO: Set yourself as the delegate and datasource here:
        
        //TODO: Set yourself as the delegate of the text field here:
        messageTextfield.delegate = self
        
            }
    ///////////////////////////////////////////
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
////////
    /////////////
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    ///////
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    // MARK: typing indicator
    private lazy var userIsTypingRef: DatabaseReference =
        self.channelRef!.child("typingIndicator").child(self.senderId) // 1
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        // 1
        usersTypingQuery.observe(.value) { (data: DataSnapshot) in
            // 2 You're the only one typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // 3 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    // MARK: Firebase related methods
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
        
    }
    ///// MARK: to upload a photo
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    /// MARK: Fetch the phots
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        // 2
        storageRef.getData(maxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.getMetadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage(data: data!)
                }
                    
                else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    // MARK: Send button action
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if userID != "718CvCRMXmd0NPzholMG1lEZ4d62"{
            
        //let messageDB = Database.database().reference().child("channels").child(userID).child("messages")
        let messageDB = Database.database().reference().child("messages")
        let itemRef = messageDB.childByAutoId() // 1
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": currentUserName,
            "text": text!
            ]
        itemRef.setValue(messageItem) // 3
        
        }
        else
        {
            let messageDB = Database.database().reference().child("messages")
            let itemRef = messageDB.childByAutoId() // 1
            let messageItem = [ // 2
                "senderId": senderId!,
                "senderName": currentUserName,
                "text": text!
            ]
            itemRef.setValue(messageItem) // 3
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
        isTyping = false
    }

    // MARK: Recieve Messages
    private func observeMessages() {
        //let messageReff = messagesRef!.child("channels").child("bagS4xRSN2N5ePnxLzjWJ3ALASG3").child("messages")
        // new comment to test git push 
 let messageReff = Database.database().reference().child("messages")
        let messageQuery = messageReff.queryLimited(toLast:25)
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            print("all messages : \(messageData)")
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                print("message text : \(text)")
                if self.userID != "718CvCRMXmd0NPzholMG1lEZ4d62" {
                    self.addMessage(withId: id, name: name, text: text)
                    
                    self.finishReceivingMessage()
                }
            }
            else if let id = messageData["senderId"] as String!,
                let photoURL = messageData["photoURL"] as String! { // 1
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    // 4
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
            else {
                print("Error! Could not decode message data")
            }
        })
        updatedMessageRefHandle = messageReff.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData["photoURL"] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
    // MARK: UI and User Interaction
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    // MARK: UITextViewDelegate methods
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    
    
    
    
    
    //TODO: Declare textFieldDidBeginEditing here:
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 320
            self.view.layoutIfNeeded()
        }
    }
    
    //TODO: Declare textFieldDidEndEditing here:
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }
    ///////////////////////////////////////////
    
    //MARK: - Send & Recieve from Firebase
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        
        //TODO: Send the message to Firebase and save it in our database
        messageTextfield.endEditing(true)
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        
        // let's create the database
        let messageDB = Database.database().reference().child("channels").child("").child("messages")
        if let MessageBody = messageTextfield.text{
            let messageDictionary = ["Sender":Auth.auth().currentUser?.email,"MessageBody":MessageBody]
            
            messageDB.childByAutoId().setValue(messageDictionary)
            {
                (error,ref) in
                if error != nil
                {
                    print("ERROR : \(error)")
                }
                else
                {
                    print("Message saved sucessfully !")
                    self.messageTextfield.isEnabled = true
                    self.sendButton.isEnabled = true
                    self.messageTextfield.text = ""
                }
            }
        }
    }
  ///////////////
    func finishThread(){
        
        messageTableView.reloadData()
        
    }
    private func observChannels() {
              DispatchQueue.main.async {
                let userID = Auth.auth().currentUser!.uid
                self.channelRefHandle = self.channelRef?.child("channels").observe(.childAdded, with: { (snapshot) -> Void in // 1
                    let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
                    let id = snapshot.key
                    if let fromName = channelData["fromName"] as! String! {
                        self.arrayOfchannels.append(id)
                             DispatchQueue.main.async(execute: self.finishThread)
                    } else {
                        print("Error! Could not decode channel data")
                    }
                })
                }
    }

     // End of the class
    }
    
// Extenion of the ChatViewController
extension ChatViewController{
    
    // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
       // if arrayOfchannels[myIndexPath.row] == users[myIndexPath.row].UID {
            return messages[indexPath.item]
        //}
//        else {
//         return messages[0]
//        }
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
       // if arrayOfchannels[myIndexPath.row] == users[myIndexPath.row].UID {
            return messages.count
        //}
        return 2
    }
    ///
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    ///
    //    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
    //        return nil
    //    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    // End of the extenion
}
///
// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // 1
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // 2
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            // 3
            if let key = sendPhotoMessage() {
                // 4
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    
                    // 5
                    let path = "\(Auth.auth().currentUser?.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    // 6
                    self.storageRef.child(path).putFile(from: imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // 7
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // Handle picking a Photo from the Camera - TODO
            // 1
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2
            if let key = sendPhotoMessage() {
                // 3
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                // 4
                let imagePath = Auth.auth().currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                // 5
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6
                storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}

