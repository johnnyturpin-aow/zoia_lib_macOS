/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct PatchPageView: View {
    
    let page: ParsedBinaryPatch.Page
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(page.index.description): \( page.name ?? "")")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.categoryLabel)
                .padding(.bottom, 2)
            PatchButtonGridView(page: page)
                .padding(.bottom, 20)
        }
        .padding(20)
        .darkGroupBackground(radius: 10)
        .frame(minWidth: 660, maxWidth: .infinity)
        .padding([.leading, .trailing], Layout.detailViewSideMargin)
        .padding(.bottom, 10)
    }
}

