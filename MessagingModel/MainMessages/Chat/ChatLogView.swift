//
//  ChatLogView.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 6/16/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
    }
    
    func handleSend() {
        print(chatText)
        guard let fromId =
            FirebaseManger.shared.auth.currentUser?.uid
            else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManger.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = ["fromId": fromId, "told": toId, "text": self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                
                self.errorMessage = "Failed to save messge into Firestore: \(error)"
                return
            }
            
            //print("Successfully saved current user sending message")
            self.chatText = ""
        }
        
        let recipientMessageDocument = FirebaseManger.shared.firestore.collection("messages")
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
            VStack(spacing: 0) {
                Spacer()
                chatBottomBar
                    //.background(Color(hue: 1.0, saturation: 0.013, brightness: 0.54))
                    .background(Color.white.ignoresSafeArea())
                
            }
            Text(vm.errorMessage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                navForMessage
                    .padding(.bottom)
            }
            
        }
        
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<20) { num in
                HStack {
                    Spacer()
                    HStack {
                        Text("Fake Text Message")
                            .foregroundColor(Color(.label))
                    }
                    .padding()
                    .background(Color(hue: 0.762, saturation: 0.658, brightness: 0.858))
                    .cornerRadius(12)
                    
                }
                .padding(.horizontal)
                .padding(.top, 6)
                
            }
            
            HStack {
                Spacer()
            }
            .frame(height: 50)
        }
        .background(Color(.init(white: 0.85, alpha: 1)))
        //.background(Color(.init(gray: 0, alpha: 0.05)))
        
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
