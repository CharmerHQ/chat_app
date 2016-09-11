//
//  chatViewController.swift
//  goChat
//
//  Created by hisham hawara on 2016-09-04.
//  Copyright © 2016 Hisham Hawara. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
class chatViewController: JSQMessagesViewController {
    var messages = [JSQMessage]()
    var avatarDict = [String : JSQMessagesAvatarImage]()
    var messageReference = FIRDatabase.database().reference().child("messages")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let currentUser = FIRAuth.auth()?.currentUser{
            senderId = currentUser.uid

            if currentUser.anonymous == true {
                self.senderDisplayName = "Anonymous"
            }
            else {
                self.senderDisplayName = "\(currentUser.displayName!)"
            
            }
        }
        
        
        observeMessages()
        // Do any additional setup after loading the view.
    }
    func observeUsers(id : String) {
        FIRDatabase.database().reference().child("users").child(id).observeEventType(.Value, withBlock: { snapshot in
            if let dict = snapshot.value as? [String : AnyObject]{
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(avatarUrl, messageId: id)
            }
        })
    }
    func setupAvatar(url : String, messageId : String){
        if url != "" {
            let fileUrl = NSURL(string: url)
            let data = NSData(contentsOfURL: fileUrl!)
            let image = UIImage(data: data!)
            let userImg = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 30)
            avatarDict[messageId] = userImg
            
        
        } else {
        avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)
        }
        collectionView.reloadData()
    
    }
    
    func observeMessages(){
        messageReference.observeEventType(.ChildAdded, withBlock: { snapshot in
            if let dict = snapshot.value as? [String : AnyObject] {
                let mediaType = dict["mediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderDisplayName = dict["senderDisplayName"] as! String
                self.observeUsers(senderId)
                if mediaType == "TEXT" {
                    let text = dict["text"] as! String
                    self.messages.append((JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)))
                }
                else if mediaType == "PHOTO" {
                    let photo = JSQPhotoMediaItem(image: nil)

                    let fileUrl = dict["fileUrl"] as! String

                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), {
                        let data = NSData(contentsOfURL: NSURL(string: fileUrl)!)
                        dispatch_async(dispatch_get_main_queue(), {
                            let picture = UIImage(data: data!)
                            photo.image = picture
                            self.collectionView.reloadData()
                        })


                    })
                    
                    self.messages.append((JSQMessage(senderId: senderId, displayName: senderDisplayName, media: photo)))
                    if self.senderId == senderId {
                        photo.appliesMediaViewMaskAsOutgoing = true
                    }
                    else {
                        photo.appliesMediaViewMaskAsOutgoing = false
                    }
                }
                else if mediaType == "VIDEO" {
                    let fileUrl = dict["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: videoItem))
                    if self.senderId == senderId {
                        videoItem.appliesMediaViewMaskAsOutgoing = true
                    }
                    else {
                        videoItem.appliesMediaViewMaskAsOutgoing = false
                    }
                
                }
                self.collectionView.reloadData()
                
            }
            
        })
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        //print("\(text)")
        //messages.append((JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)))
        let newMessage = messageReference.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderDisplayName": senderDisplayName, "mediaType": "TEXT"]
        self.finishSendingMessage()
        newMessage.setValue(messageData)
        collectionView.reloadData()
    }
    override func didPressAccessoryButton(sender: UIButton!) {
        let Sheet = UIAlertController(title: "Location Information", message: "Photo/Video", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let Cancel = UIAlertAction(title: "Cancel", style:UIAlertActionStyle.Cancel) { (alert :UIAlertAction) in
        }
        
        let PhotoLibary = UIAlertAction(title: "Select a Photo", style: UIAlertActionStyle.Default) { (alert :UIAlertAction) in
            self.getMediaFrom(kUTTypeImage)
        }
        let VideoLibary = UIAlertAction(title: "Select a Video", style: UIAlertActionStyle.Default) { (alert :UIAlertAction) in
            self.getMediaFrom(kUTTypeMovie )
        }
        
        self.presentViewController(Sheet, animated: true, completion: nil)
        Sheet.addAction(PhotoLibary)
        Sheet.addAction(VideoLibary)
        Sheet.addAction(Cancel)
        
    }
    
    func getMediaFrom(type:CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
        
        print(type)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId {
        return bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.blackColor())
        } else {
            return bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.blueColor())
        }
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        return avatarDict[message.senderId]
        //return JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)
    }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = messages[indexPath.item]
        if message.isMediaMessage {
            if let mediaItem = message.media as? JSQVideoMediaItem {
                let player = AVPlayer(URL: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.presentViewController(playerViewController, animated: true, completion: nil)
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutTapped(sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
        }
        catch let error {
            print(error)
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let loginVc = storyBoard.instantiateViewControllerWithIdentifier("LogInVc") as! loginViewController
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appdelegate.window?.rootViewController = loginVc
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    func getMedia(picture: UIImage?, video: NSURL?) {
        if let picture = picture {
            let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
            let data = UIImageJPEGRepresentation(picture, 0.1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error)
                }
                let fileUrl = metadata?.downloadURLs![0].absoluteString
                let newMessage = self.messageReference.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderDisplayName": self.senderDisplayName, "mediaType": "PHOTO"]
                newMessage.setValue(messageData)
                
            }
        }
            
            
        else if let video = video {
            let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
            let data = NSData(contentsOfURL: video)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error)
                }
                let fileUrl = metadata?.downloadURLs![0].absoluteString
                let newMessage = self.messageReference.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderDisplayName": self.senderDisplayName, "mediaType": "VIDEO"]
                newMessage.setValue(messageData)
                
            }
        }
        
    }
}


extension chatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.getMedia(picture, video: nil)
            
        }
        else if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            self.getMedia(nil, video: video)
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
}
