//
//  RecentMessage.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 7/23/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable {
    
//    var id: String { documentId}
    @DocumentID var id: String?
    
    let text, email: String //decode
    let fromId, toId: String //decode
    let profileImageUrl: String
    let timestamp: Date
    

}
