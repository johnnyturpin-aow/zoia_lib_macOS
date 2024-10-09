/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI


struct Layout {
    
    static let rowHeight: CGFloat = 64
    static let detailViewSideMargin: CGFloat = 30
}

struct AppColors {
    static let groupBackground: Color = Color("groupBackground")
    static let pageBackground: Color = Color("pageBackground")
    static let ioNormal: Color = Color("ioNormal")
    static let ioActivated: Color = Color("ioActivated")
    static let tertiaryMetadata: Color = Color("tertiaryMetadata")
    static let shadowColor: Color = Color("shadowColor")
    static let categoryLabel: Color = Color("categoryLabel")
    static let categoryStroke: Color = Color("categoryStroke")
    static let tagLabel: Color = Color("tagLabel")
    static let useDarkGroupBackground = true
}


extension View {

    func detailImageStyle() -> some View {
        self.cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5)
            .stroke(Color.black, lineWidth: 2))
            .shadow(color: AppColors.shadowColor, radius: 2, x: 0, y: 2)
    }
    
    
    func groupStyle(radius: CGFloat) -> some View {
        
        self.background(AppColors.groupBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: AppColors.shadowColor, radius: 2, x: 1, y: 1)
    }
    
    func darkGroupBackground(radius: CGFloat) -> some View {
        self.background(AppColors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: AppColors.shadowColor, radius: 2, x: 1, y: 1)
    }
}

extension PatchStorage {
    static func colorForCategory(categoryName: String?) -> Color? {
        
        switch categoryName?.lowercased() {
        case "synthesizer":
            return Color.init("CategorySynth")
        case "effect":
            return Color.init("CategoryEffect")
        case "sampler":
            return Color.init("CategorySampler")
        case "sequencer":
            return Color.init("CategorySequencer")
        case "sound":
            return Color.init("CategorySound")
        default:
            return nil
        }
    }
    
    static func colorForTagSelected(tagName: String?) -> Color? {
        
		if tagName?.lowercased().contains("midi") == true || tagName?.lowercased().contains("clock") == true {
			return Color.init("TagMidiSelected")
		}
		if tagName?.lowercased().contains("sample") == true || tagName?.lowercased().contains("loop") == true {
			return Color.init("TagSamplerSelected")
		}
		if tagName?.lowercased().contains("ambient") == true {
			return Color.init("TagAmbientSelected")
		}
		if tagName?.lowercased().contains("synth") == true || tagName?.lowercased().contains("drone") == true {
			return Color.init("TagSynthSelected")
		}
        if tagName?.lowercased().contains("delay") == true || tagName?.lowercased().contains("multi-tap") == true || tagName?.lowercased().contains("ping") == true || tagName?.lowercased().contains("granular") == true || tagName?.lowercased().contains("grain") == true || tagName?.lowercased().contains("echo") == true {
            return Color.init("TagDelaySelected")
        }
        if tagName?.lowercased().contains("reverb") == true {
            return Color.init("TagReverbSelected")
        }
        if tagName?.lowercased().contains("chorus") == true || tagName?.lowercased().contains("flange") == true || tagName?.lowercased().contains("trem") == true {
            return Color.init("TagModulationSelected")
        }
        if tagName?.lowercased().contains("distortion") == true || tagName?.lowercased().contains("overdrive") == true || tagName?.lowercased().contains("comp") == true {
            return Color.init("TagDistortionSelected")
        }

        return nil
    }
    
    static func colorForTag(tagName: String?) -> Color? {
        
		if tagName?.lowercased().contains("midi") == true || tagName?.lowercased().contains("clock") == true {
			return Color.init("TagMidi")
		}
		
		if tagName?.lowercased().contains("sample") == true || tagName?.lowercased().contains("loop") == true {
			return Color.init("TagSampler")
		}
		
		if tagName?.lowercased().contains("ambient") == true {
			return Color.init("TagAmbient")
		}
		
		if tagName?.lowercased().contains("synth") == true || tagName?.lowercased().contains("drone") == true  {
			return Color.init("TagSynth")
		}
		
        if tagName?.lowercased().contains("delay") == true || tagName?.lowercased().contains("multi-tap") == true || tagName?.lowercased().contains("ping") == true || tagName?.lowercased().contains("granular") == true || tagName?.lowercased().contains("grain") == true || tagName?.lowercased().contains("echo") == true {
            return Color.init("TagDelay")
        }
        if tagName?.lowercased().contains("reverb") == true {
            return Color.init("TagReverb")
        }
        if tagName?.lowercased().contains("chorus") == true || tagName?.lowercased().contains("flange") == true || tagName?.lowercased().contains("trem") == true {
            return Color.init("TagModulation")
        }
        if tagName?.lowercased().contains("distortion") == true || tagName?.lowercased().contains("overdrive") == true || tagName?.lowercased().contains("comp") == true {
            return Color.init("TagDistortion")
        }

        return nil
    }
}

