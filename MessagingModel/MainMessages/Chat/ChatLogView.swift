//
//  ChatLogView.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 6/16/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

//constants for strings
struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let messages = "messages"
    static let recentMessages = "recent_messages"
    static let profileImageUrl = "profileImageUrl"
    static let email = "email"

}

//Chat log Model and functions
class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage] ()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    //fetches messages
    private func fetchMessages() {
        guard let fromId =
            FirebaseManager.shared.auth.currentUser?.uid
            else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
        
    }
    
    func handleSend() {
        print(chatText)
        guard let fromId =
            FirebaseManager.shared.auth.currentUser?.uid
            else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                
                self.errorMessage = "Failed to save messge into Firestore: \(error)"
                return
            }
            
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print(error)
                
                self.errorMessage = "Failed to save messge into Firestore: \(error)"
                return
            }
            
            //print("Recipient saved message as well")
        }
        
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return }
        
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages).document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ]  as [String : Any]
        
        //dictionary for recipient of message
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent messages: \(error)"
                print("Failed to save recent message: \(error)")
                return
            }
        }
        //fix dictionary
        guard let currentUser = FirebaseManager.shared.auth.currentUser else { return }
        let recipientRecentMessageDictionary = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            //FirebaseConstants.profileImageUrl: currentUser.profileImageUrl,
            FirebaseConstants.email: currentUser.email
        ] as [String: Any]
        
        
    }
    
    @Published var count = 0
}

struct ChatLogView: View { 
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        
        ZStack {
            messagesView
//            VStack(spacing: 0) {
//                Spacer()
//                chatBottomBar
//                    //.background(Color(hue: 1.0, saturation: 0.013, brightness: 0.54))
//                    .background(Color.white.ignoresSafeArea())
//
//            }
            Text(vm.errorMessage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                navForMessage
                    .padding(.bottom)
            }
            
        }
//        .navigationBarItems(trailing: Button(action: {
//            vm.count += 1
//        }, label: {
//            Text("count: \(vm.count)")
//        }))
        
    }
    
    static let emptyScrollTo = "Empty"
    
    private var messagesView: some View {
        VStack {
            //if ios 15 available
            ScrollView {
                ScrollViewReader{ scrollViewProxy in
                    VStack {
                            ForEach(vm.chatMessages) { message in
                                MessageView(message: message)
                                
                            }
                            
                            HStack { Spacer() }
                            .id(Self.emptyScrollTo)
                    }
                    .onReceive(vm.$count) { _ in
                        withAnimation(.easeIn(duration: 0.15)) {
                            scrollViewProxy.scrollTo(Self.emptyScrollTo, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.init(white: 0.85, alpha: 1)))
            //.background(Color(.init(gray: 0, alpha: 0.05)))
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .background(Color(.systemBackground)
                        .ignoresSafeArea())
            }
        }
        
        
        
    }
    
    private var navForMessage: some View {
        HStack {
            WebImage(url: URL(string: chatUser?.profileImageUrl ?? ""))
                .resizable()
                //.scaledToFill()
                .frame(width: 40, height: 40, alignment: .leading)
                .clipped()
                .cornerRadius(50)
                //.overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(.label), lineWidth: 1.5))
            
            Text(chatUser?.email ?? "")
                .foregroundColor(Color(.label))
        }
        .padding()
        //.background(Color("VPurple").ignoresSafeArea())
    }
    
    private var chatBottomBar: some View {
        
        HStack(spacing: 16) {
            Button {
                
            } label: {
                Image(systemName: "photo.tv")
                    .font(.system(size: 24))
                    .foregroundColor(Color(.darkGray))
                    //.background(Color("Vpurple"))
            }
            //.padding(.horizontal)
            //.padding(.vertical, 8)
            
            ZStack {
                //@Published var space: CGFloat = 0.0
                
                if(vm.chatText == "") {
                    DescriptionchatText()
                    
                }

                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
                    .padding(.horizontal, 5)
                
            }
            .frame(height: 35)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.darkGray), lineWidth: 1))
            
            
            Button {
                vm.handleSend()
                
            } label: {
                Image(systemName: "paperplane.fill")
                    .padding(.leading, -3.0)
                    .font(.system(size: 26))
                    .foregroundColor(Color("VPurple"))
            }
            //.padding(.horizontal)
            .padding(.vertical, 8)

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        
    }
    
    
}

struct MessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(Color(.label))
                    }
                    .padding()
                    .background(Color(hue: 0.762, saturation: 0.658, brightness: 0.858))
                    .cornerRadius(12)
                    
                }
                
                
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(Color(.label))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    Spacer()
                    
                }
                
                
            }
            
        }
        .padding(.horizontal)
        .padding(.top, 6)
        
    }
}

private struct DescriptionchatText: View {
    var body: some View {
        HStack {
            Text("Type Message..")
                .foregroundColor(Color.gray)
                .font(.system(size: 18))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()

        }
    }

}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            ChatLogView(chatUser: .init(data: ["uid" : "7J4ioZG6L2Y6Z1SMyGRgbSgdRab2", "email" : "saveduser5@gmail.com", "profileImageUrl" : "https://firebasestorage.googleapis.com:443/v0/b/messaging-swiftui-firebasechat.appspot.com/o/7J4ioZG6L2Y6Z1SMyGRgbSgdRab2?alt=media&token=ad902b6b-6e78-42fe-a1f6-2c22d9f39c38"]))
//        }
        MainMessagesView()
    }
}
