/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct BankRowView: View {
    
    let patch: PatchFile
    let index: Int

    var body: some View {
        HStack {
            Text(index.description)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Color.init(red: 0.5, green: 0.5, blue: 0.5))
                .frame(width: 30)
                .padding(.leading, 10)
            
            Image(systemName: patch.isFactoryPatch ? "lock" : patch.patchType.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30)
                .opacity(patch.patchType.iconOpacity)
                .padding([.top, .bottom], 3)
                .padding(.leading, 10)
                .padding(.trailing, 5)
                .draggablePatch(patch: patch)

            Text(patch.name ?? "")
                .frame(width: 200, alignment: .leading)
                .padding(0)
            Text("Pages = \(patch.numPages)")
                .frame(width: 100, alignment: .leading)
                .padding(0)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.init(red: 0.5, green: 0.5, blue: 0.5))
            Text(patch.isFactoryPatch ? "Factory" : patch.patchTypeDescription)
                .frame(width: 150, alignment: .leading)
                .padding(0)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.tertiary)
            Text(patch.isEuroBoro ? "Euroburo" : "ZOA"  )
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.tertiary)
                .padding(0)
            Spacer()
        }
        .frame(height: 28)
        .padding(.top, 2)
        .padding(.bottom, 2)

    }
}

