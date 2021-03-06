//
//  MainMessagesView.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 6/5/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift



//observable Object -> view for the current user
class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    
    
    init() {//initializes log out check
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
            
        }
        
        
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessage]()
    
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return }
        
        FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    //had error
                    do {
                        if let rm = try? change.document.data(as: RecentMessage.self) {
                            self.recentMessages.insert(rm, at: 0)
                        }
                    } catch {
                        print(error)
                    }
                    
                })
            }
        
    }
    
    //Gets the data for current user logged in from Firebase
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Couldn't find firebase uid"
            return }
        
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                
                self.errorMessage = "Failed to fetch current user: \(error)"
                
                print("Failed to fetch current user:", error)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "No Data Found"
                return
                
            }
            
            self.chatUser = .init(data: data)
            
        }
    }
    
    
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}

struct MainMessagesView: View {
    //Vars for messages view functioning
    @State var shouldShowLogOutOption = false
    
    @State var shouldNavigateToChatLogView = false //var for new message page navi link
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    //Messages view
    var body: some View {
        NavigationView {
            
            
                VStack {
                    
                    customNavBar
                    messagesView
                    
                    NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                        ChatLogView(chatUser: self.chatUser)
                    }

                }
                .overlay(
                    newMessageButton, alignment: .bottomTrailing)
                .navigationBarHidden(true)
            
        }
    }
    
    //top nav bar
    private var customNavBar: some View {
        //nav bar layout
        HStack {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? "")).resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                //change this to do it for all emails
                let email =
                vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                
                Text(email)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(Color(.label))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            
            
            Spacer()
            
            Button {
                shouldShowLogOutOption.toggle()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(Color(hue: 0.765, saturation: 0.929, brightness: 0.759))
                    .padding(.all, 9.0)
                    .background(Color(hue: 3.0, saturation: 0.053, brightness: 0.750))
                    .clipShape(Circle())
                    .font(.system(size: 21.6, weight: .semibold))
            }

            
        }
        .padding([.leading, .bottom, .trailing])
        .background(Color(hue: 0.765, saturation: 0.929, brightness: 0.759)
            .ignoresSafeArea())
        .actionSheet(isPresented: $shouldShowLogOutOption) {
            .init(title: Text("Settings")                       .font(.system(size: 20)), buttons: [
                .destructive(Text("sign out"), action: {
                    print("handle sign out")
                    
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        }//handles transitions from sign out button
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                
            })
        }
        
    }
    
    //messages feed
    private var messagesView: some View {
        //scrollview for messages
        ScrollView{
            
            messageRow
            
            
        }
        
    }
    
    @State var shouldShowNewMessageScreen = false //controls if new message pops up with button
    
    //plus button
    private var newMessageButton: some View {
        
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            
            Image(systemName: "plus")
                .foregroundColor(.white)
                .padding()
                .background(Color(hue: 0.765, saturation: 0.929, brightness: 0.759))
                .clipShape(Circle())
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()//not style
                self.chatUser = user
            })
        }
    }
    
    private var messageRow: some View {

        ForEach(vm.recentMessages) { recentMessage in
            NavigationLink {
                Text("Destination")
            } label: {

                VStack {
                    HStack(spacing: 16){ //one message view
                        
                        WebImage(url: URL(string: recentMessage.profileImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(50)
                            .shadow(radius: 5)

                        
                        VStack(alignment: .leading){
                            HStack {
                                Text(recentMessage.email)
                                .font(.system(size: 16, weight: .bold))
                                .multilineTextAlignment(.leading)

                                Spacer()
                                
                                Text(recentMessage.timeAgo)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(recentMessage.text)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.darkGray))
                                .multilineTextAlignment(.leading)
                            }
                            
                        }
                        Divider()
                        .padding(.vertical, 8)
                        
                }
                .padding(.horizontal)
            }
            .foregroundColor(Color(.label))

        }
        .padding(.bottom, 50)
        
    }
    
    @State var chatUser: ChatUser?
}


struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            //.preferredColorScheme(.dark)
        
        //MainMessagesView()
    }
}
