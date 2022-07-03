//
//  FirebaseManager.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 6/7/22.
//

import Foundation
import Firebase
import FirebaseStorage


class FirebaseManger: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManger()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
        
    }
}
