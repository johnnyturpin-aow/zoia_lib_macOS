/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct PatchIOView: View {
    
    let numPages: Int
    let patch_io: ParsedBinaryPatch.IO

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 20.0))
                        .foregroundColor(AppColors.ioNormal)

                    Text(patch_io.estimated_cpu)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.ioNormal)
                    Spacer()
                }
                .padding(.bottom, 2)
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 20.0))
                        .foregroundColor(AppColors.ioNormal)

                    Text(numPages.description)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.ioNormal)
                    Spacer()
                }
                
            }
            .padding(.leading, 10)
            .frame(width: 110)
            VStack(alignment: .leading) {
                HStack {
                    
                    Text("Audio In:")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .trailing)
                    Image(systemName: "l.circle")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.audio_input_list[1] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "r.circle")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.audio_input_list[2] == true ? AppColors.ioActivated : AppColors.ioNormal)

                    Spacer()
                }
                .padding(.bottom, 2)
                HStack {
                    
                    Text("Audio Out:")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .trailing)
                    Image(systemName: "l.circle.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.audio_output_list[1] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "r.circle.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.audio_output_list[2] == true ? AppColors.ioActivated : AppColors.ioNormal)

                    Spacer()
                }
                
            }
            .frame(width: 140)
            VStack(alignment: .leading) {
                HStack {
                    
                    Text("CV In:")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .trailing)
                    Image(systemName: "1.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_in[1] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "2.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_in[2] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "3.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_in[3] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "4.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_in[4] == true ? AppColors.ioActivated : AppColors.ioNormal)

                    Spacer()
                }
                
                .padding(.bottom, 2)
                HStack {
                    
                    Text("CV Out:")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .trailing)
                    Image(systemName: "1.square.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_out[1] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "2.square.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_out[2] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "3.square.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_out[3] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "4.square.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.cv_out[4] == true ? AppColors.ioActivated : AppColors.ioNormal)

                    Spacer()
                }
            }
            .opacity(patch_io.has_cv ? 1.0 : 0.3)
            .frame(width: 210)
            VStack(alignment: .center) {
                Text("Stomp")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.ioNormal)
                    .padding(.bottom, 5)
                HStack {
                    Spacer()
                    Image(systemName: "circle.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.stomp_switch[1] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "circle.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.stomp_switch[2] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Image(systemName: "circle.square")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.stomp_switch[3] == true ? AppColors.ioActivated : AppColors.ioNormal)
                    Spacer()
                }
            }
            .opacity(patch_io.has_stomp ? 1.0 : 0.3)
            .frame(width: 130)
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "circle.hexagongrid.circle")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.has_midi_in == true ? AppColors.ioActivated : AppColors.ioNormal)
                        .padding(.bottom, 2)
                    Text(patch_io.midi_input_description)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .leading)
                }
                .opacity(patch_io.has_midi_in ? 1.0 : 0.3)
                HStack {
                    Image(systemName: "circle.hexagongrid.circle.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(patch_io.has_midi_out == true ? AppColors.ioActivated : AppColors.ioNormal)
                        .padding(.bottom, 2)
                    Text(patch_io.midi_output_description)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(AppColors.ioNormal)
                        .frame(width: 75, alignment: .leading)
                }
                .opacity(patch_io.has_midi_out ? 1.0 : 0.3)
            }
            
            .frame(width: 150)
            Spacer()
        }
    }
}


