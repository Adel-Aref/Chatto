//
//  RegisterViewController.swift
//  Flash Chat
//
//  This is the View Controller which registers new users with Firebase
//

import UIKit
import Firebase


class RegisterViewController: UIViewController {

     private lazy var channelRef: DatabaseReference = Database.database().reference().child("Users")
    //Pre-linked IBOutlets
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

  
    @IBAction func registerPressed(_ sender: AnyObject) {
        if let email = emailTextfield.text, let password = passwordTextfield.text{
            //TODO: Set up a new user on our Firbase database
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                if error != nil
                {
                    print("ERROR : \(error?.localizedDescription)")
                    let action = UIAlertAction()
                    
                    let alert = HelpingMethods.showAlert(title: "Warning message", message:(error?.localizedDescription)!, action:action, actionName: "OK")
                    self.present(alert, animated: true, completion: nil)
                }
                else
                {
                    print("SUCCESS")
                    let displayName = self.nameTextField.text
                    let newChannelRef = self.channelRef.child((Auth.auth().currentUser?.uid)!) // 2
                    let channelItem = [ // 3
                        "displayName": displayName,
                        "email":Auth.auth().currentUser?.email,
                        "userId":Auth.auth().currentUser?.uid
                    ]
                    newChannelRef.setValue(channelItem) // 4
                    self.performSegue(withIdentifier: "signUpToChannels", sender: self)
                }
            })
            
        }
        else
        {
            
        }
        
        // End of the action
    }
    
    
    // End of the class
    } 

