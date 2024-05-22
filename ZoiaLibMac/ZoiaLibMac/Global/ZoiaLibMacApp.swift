/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import Combine


@main
struct ZoiaLibMacApp: App {
    
    @StateObject private var appModel = AppViewModel()
    @State var showConfirmBankDelete: Bool = false
    @State var customScheme: AppearanceOptions = AppearanceOptions()
    @Environment(\.scenePhase) private var scenePhase
    
    @State var minSize:CGSize = {
        guard let screen = NSScreen.main?.frame.size
        else { return CGSize(width: 1200, height: 800) }
        return CGSize(width: screen.width, height: screen.height)
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(showConfirmDelete: $showConfirmBankDelete)
                .environmentObject(appModel)
                .padding(.bottom, 1)
                .frame(minWidth: 800, minHeight: 800)
                .alert(isPresented: $appModel.alerter.isShowingAlert) {
                    appModel.alerter.alert ?? Alert(title: Text(""))
                }
                .alert("Confirm Delete", isPresented: $showConfirmBankDelete, actions: {
                    Button(role: .destructive) {
                        appModel.deleteBank(bank: appModel.selectedBank) {
                            didSucceed in
                            let alerter = Alerter()
                            alerter.alert = Alert(title: Text(didSucceed ? "Bank successfuly deleted" : "Bank failed to be deleted"))
                            appModel.alerter = alerter
                        }
                    } label: {
                        Text("Delete")
                    }
                }, message: {
                    Text("Are your sure your would like to delete: \(appModel.selectedBank?.name ?? "")?")
                })
                .onChange(of: customScheme, perform: {
                    newValue in
					UserDefaults.standard.set(newValue.rawValue, forKey: "AppInterfaceStyle")
                })
                .preferredColorScheme(customScheme == .System ?
                                      AppearanceOptions() == .Light ? .light : .dark :
                                        customScheme == .Light ? .light : .dark)
        }
        .windowToolbarStyle(.automatic)
        .commands {
            SidebarCommands()
            BankCommands(showConfirmDelete: $showConfirmBankDelete, model: appModel, customScheme: $customScheme)
        }
        
        WindowGroup {
            NodeCanvasView()
                .environmentObject(appModel)
                .frame(minWidth:  600, idealWidth: .infinity, maxWidth: .infinity, minHeight: 600, idealHeight: .infinity, maxHeight: .infinity)
                .background(Color("nodeViewBackground"))
        }
        .handlesExternalEvents(matching: ["file"])
    }
}



class Alerter: ObservableObject {
    @Published var alert: Alert? {
        didSet {
            isShowingAlert = alert != nil
        }
    }
    @Published var isShowingAlert = false
    
    var completion: (()->Void)?
}

