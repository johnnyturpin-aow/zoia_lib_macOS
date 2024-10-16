/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct PatchButtonGridView: View {
    
    let page: ParsedBinaryPatch.Page
    
    let columns: [GridItem] = Array(repeating: .init(.fixed(70), spacing: 5, alignment: .center), count: 8)
    var body: some View {
        
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(page.buttons, id: \.self) { button in
                Text("")
                    .frame(width: 70, height: 70)
                    .background(button.buttonColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.init(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3))
                    .overlay(LabelOverlay(label: button.label, labelWidth: button.labelWidth))
            }
        }
        .padding(20)
    }
}

struct LabelOverlay: View {
    
    let label: String?
    let labelWidth: Int
    
    var body: some View {
        if let label = label {
            VStack {
                Text(label)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(Color.white)
                    .padding(5)
					.multilineTextAlignment(.center)
                    .background(Color.init(red: 0, green: 0, blue: 0, opacity: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.trailing, CGFloat(labelWidth - 1) * 70)
                    
            }
            .frame(width: CGFloat(labelWidth * 70))
        }
    }
}

