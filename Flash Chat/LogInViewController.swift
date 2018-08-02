//
//  LogInViewController.swift
//  Flash Chat
//
//  This is the view controller where users login


import UIKit
import Firebase
import SVProgressHUD

class LogInViewController: UIViewController {
   

    //Textfields pre-linked with IBOutlets
    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

   
    @IBAction func logInPressed(_ sender: AnyObject) {

        //TODO: Log in the user
        if let email = emailTextfield.text, let password = passwordTextfield.text{
            
            //TODO: Set up a new user on our Firbase database
            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                SVProgressHUD.show()
                if error != nil{
                    print("Error: \(error?.localizedDescription)")
                    SVProgressHUD.dismiss(withDelay: 0.1)
                    
                }
                else{
                    print("Login Success ")
                    //SVProgressHUD.dismiss(withDelay: 1)
                    self.performSegue(withIdentifier: "logToChat", sender: self)
                }
            })
        
        }
    
    }
    // MARK: Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//        let navVc = segue.destination as! UINavigationController // 1
//        let channelVc = navVc.viewControllers.first as! ChannelListVC // 2
//        
//        channelVc.senderDisplayName = emailTextfield?.text // 3
//    }
    // End of the class
}  
