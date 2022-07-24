//
//  ContentView.swift
//  MessagingModel
//
//  Created by Alvin Ishimwe on 5/30/22.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore



struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    //vars for view
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State var shouldShowImagePicker = false
    
    //login page
    var body: some View {
        
        //login page view
        NavigationView {
            ScrollView {
                
                VStack(spacing: 16){
                    //picker for login and create account options
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    
                    //if in create account gives option to pick image
                    if !isLoginMode {
                        
                        Button {
                            shouldShowImagePicker.toggle()
                            
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    VStack {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 75))
                                            .foregroundColor(Color(hue: 0.765, saturation: 0.929, brightness: 0.759))
                                        Text("Upload a picture")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(Color(hue: 0.765, saturation: 0.929, brightness: 0.759))
                                    }
                                    .padding()
                                    
                                }
                                
                            }
                            
                            
                        }
                        
                    } else {
                        //just login option
                        
                        Spacer()
                    }
                    //input fields
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(15)
                    .background(Color.white)
                    .clipShape(Capsule())

                    
                    
                    Button {
                        handleAction()
                    } label: {
                        
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("VPurple"))
                                .clipShape(Capsule())
                                .font(.system(size: 17, weight: .heavy))
                        
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    
                }
                .padding()
                
                
                
                 
            }
            
            
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isLoginMode ? "Log In" : "Create Account")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .padding()
            .background(Color(.init(gray: 0, alpha: 0.05))
                .ignoresSafeArea())
            
            
            

        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
        
        
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        
        if isLoginMode {
            //print("Should log into Firebase with existing credentials")
            loginUser()
        } else {
            createNewAccount()
            //print("Register a new account inside firebase auth and then store image in storage somehow")
            
        }
    }
    
    @State var loginStatusMessage = ""
    
    //handles user logging in
    private func loginUser() {
        //authenicates user with firebase
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            
            //error messages
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            
            //prints success to console and in view
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()//call to func that sends the page to the messages view
        }
        
    }
    
    
    //function for creating a new account
    private func createNewAccount() {
        if self.image == nil {//checks if avatar is selected
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        //creates user with firebase
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()//calles on image save function
        }
    }
    
    //saves the image to the storage
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData) { metadata, err in
            //error message
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    
                    return
            }
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString)
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)//call to func to save user with their image
            }
        }
    }
    
    //func for storing users info when logged in
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return  }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("Success")
                
                self.didCompleteLoginProcess()
            }
    
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
        
    }
}
