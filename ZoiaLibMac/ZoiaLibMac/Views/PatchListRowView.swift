//
//  PatchListContentView.swift
//  ZoiaLibMac
//
//  Created by Johnny Turpin on 4/5/22.
//

import SwiftUI
import WrappingHStack

// Title : Tags : Categories : Date Modified : Download Now

// how to detect colorScheme
//  @Environment(\.colorScheme) var colorScheme
struct PatchListRowDesignWIP: View {
    
    @State var tags = ["Abmient", "Drone", "Eerir", "Ring-mod", "Landscape"]
    
    var body: some View {
        HStack {
            Image("ZoiaholeA-3-1024x737")
                .resizable()
                .scaledToFill()
                .frame(width: 104, height: 74, alignment: .center)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Transmogrifier")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.init("PatchLabelTitle"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text("Christopher H. M.Jacques")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.init("PatchNameLabel"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text("03/03/2022")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            Text("a highly customizable, glitchy, granular, looper delay. Thing.")
                .font(.system(size: 19, weight: .bold)).italic()
                .foregroundColor(Color.init("PatchDescriptionLabel"))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.leading, 10)
                
            VStack {
                Text("Synthesizer")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.init("PatchLabelTitle"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text("Sequencer, Looper")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.init("PatchLabelTitle"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            .padding(25)
            .background(Color.init("PatchSynthCollectionBackground"))
            WrappingHStack(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.gray)
                    .padding(2)
                    .overlay( RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1))
                    .padding(.top, 5)
            }
            .padding(.leading, 5)
            .frame(maxWidth: 200)
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 42.0))
                //.foregroundColor(.red)
            Spacer()
        }
    }
}


struct PatchListContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            PatchListRowDesignWIP()
                .preferredColorScheme($0)
                .frame(width: 1200, height: 74)
        }

    }
}
