//
//  CreateNewMessageView.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 6/13/22.
//

import SwiftUI
import SDWebImageSwiftUI


//change to show friends or contacts
class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManger.shared.firestore.collection("users")
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch users: \(error)"
                    print("Failed to fetch users: \(error)")
                    return
                }
                
                //use to figure out how to store friends in firebase
                //create a class or struct thats connected to uid that shows friends
                //access contacts to get them and appends them to the user data
                documentsSnapshot?.documents.forEach({ snapshot in
                    let data = snapshot.data()//option to show yourself as part of the new messages
                    let user = ChatUser(data: data)
                    if user.uid != FirebaseManger.shared.auth.currentUser?.uid {
                        self.users.append(.init(data: data))
                    }
                    
                })
                
            }
    }
    
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(vm.errorMessage)
                
                ForEach(vm.users) {user in
                    Button{
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 62, height: 62, alignment: .leading)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(hue: 0.765, saturation: 0.929, brightness: 0.759), lineWidth: 1.5))
                            
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    Divider()

                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }

                }
            }
        }
    }
}


struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
//        CreateNewMessageView()
//            .preferredColorScheme(.dark)
        MainMessagesView()
    }
}
