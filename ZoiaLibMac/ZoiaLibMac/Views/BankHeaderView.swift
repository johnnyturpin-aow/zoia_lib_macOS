/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct BankHeaderView: View {
    
    @ObservedObject var bank: Bank
    
    @State private var isEditingName: Bool = false
    @State private var isEditingDescription: Bool = false
    @State var bankName: String
    @State var bankDescription: String
    
    @State private var bgColor: Color
    @State private var fgColor: Color
    
    @State private var dragOver = false
    @State private var colorGroupExpanded: Bool = false
    @EnvironmentObject private var model: AppViewModel
    
    @State private var updateTimer: Timer?
    
    init(bank: Bank) {
        self.bank = bank
        self.bankName = bank.name
        self.bankDescription = bank.description ?? ""
        self.bgColor = bank.image.backgroundColor
        self.fgColor = bank.image.iconColor
    }
    var body: some View {
    
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    switch bank.image.imageType {
                    case .icon:
                        Image(systemName: bank.image.icon.sysImageName)
                            .font(.system(size: 60))
                            .foregroundColor(bank.image.iconColor)
                            .onDrop(of: ["public.file-url"], isTargeted: $dragOver, perform: {
                                providers in
                                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                                    if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                                        BankManager.saveImageFileToBank(bank: bank, imageUrl: url)
                                    }
                                })
                                return true
                            })
                    case .image:
                        Image(nsImage: bank.nsImage ?? NSImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onDrop(of: ["public.file-url"], isTargeted: $dragOver, perform: {
                                providers in
                                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                                    if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                                        BankManager.saveImageFileToBank(bank: bank, imageUrl: url)
                                    }
                                })
                                return true
                            })
                    }
                }
                .frame(width: 120, height: 120, alignment: .center)
                .background(bank.image.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.leading, 20)
                .contextMenu {
                    Menu("Select Icon Image") {
                        ForEach(Bank.BankImage.Icon.allCases, id: \.self) {
                            icon in
                            Button(action: {
                                bank.image.imageType = .icon
                                bank.image.icon = icon
                            }, label: {
                                HStack {
                                    Text(icon.rawValue)
                                    Image(systemName: icon.sysImageName)
                                    Spacer()
                                }
                            })
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                }
                VStack(alignment: .leading) {
                    if isEditingName {
                        TextField(bank.name, text: $bankName)
                            .frame(width: 300, height: 40)
                            .font(.system(size: 30, weight: .bold))
                            .border(.red, width: 2)
                            .onSubmit {
                                bank.name = self.bankName
                                self.isEditingName = false
                                model.currentSidebarSelection = bank.name
                                BankManager.updateBankName(bank: bank, newName: bankName)
                            }
                    } else {
                        Text(bank.name)
                            .frame(width: 300, height: 40, alignment: .leading)
                            .font(.system(size: 30))
                            .onTapGesture(count: 1, perform: {
                                self.isEditingName = true
                            })
                    }
                    if isEditingDescription {
                        TextField(bank.description ?? "", text: $bankDescription)
                            .font(.system(size: 14, weight: .regular))
                            .border(.red, width: 2)
                            .onSubmit {
                                bank.description = self.bankDescription
                                self.isEditingDescription = false
                                BankManager.updateBankMetadata(bank: bank)
                            }
                    } else {
                        Text(bank.description ?? "")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.init(red: 0.5, green: 0.5, blue: 0.5))
                            .lineLimit(1)
                            .padding(.bottom, 5)
                            .onTapGesture(count: 1, perform: {
                                self.isEditingDescription = true
                            })
                    }

                    Text("Num Items: \(bank.numItems.description)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.init(red: 0.5, green: 0.5, blue: 0.5))
                        .lineLimit(1)
                        .onSubmit {
                            bank.image.backgroundColor = self.bgColor
                            BankManager.saveBank(bank: bank)
                        }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                
                if bank.image.imageType == .icon {
                    VStack(alignment: .leading) {
                        DisclosureGroup("Colors", isExpanded: $colorGroupExpanded) {
                            ColorPicker(selection: $bgColor, label: { Text("BG Color") })
                            ColorPicker(selection: $fgColor, label: {Text("FG Color") })
                        }
                        .frame(width: 150, alignment: .leading)

                        Spacer()
                    }
                    .padding(.top, 20)
                }
                Spacer()
            }
            .onChange(of: self.bgColor, perform: {
                newValue in
                bank.image.backgroundColor = newValue
                updateTimer?.invalidate()
                updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {
                    _ in
                    BankManager.updateBankMetadata(bank: bank)
                }
            })
            .onChange(of: self.fgColor, perform: {
                newValue in
                bank.image.iconColor = newValue
                BankManager.updateBankMetadata(bank: bank)
            })
            .padding(.leading, 10)
        }
    }
}

