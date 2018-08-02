//
//  Channel.swift
//  Flash Chat
//
//  Created by Adel on 7/30/18.
//  Copyright © 2018 London App Brewery. All rights reserved.
//

import Foundation

internal class Channel {
    internal var fromId: String
    internal var fromName: String
    internal let toId: String
    internal let toName: String
    
    init(Fid: String, Fname: String,Tid: String, Tname: String) {
        self.fromId = Fid
        self.fromName = Fname
        self.toId = Tid
        self.toName = Tname
    }
}
