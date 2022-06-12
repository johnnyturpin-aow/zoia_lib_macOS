/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation
import SwiftUI
import CoreGraphics


extension CGSize {
  func scaledDownTo(_ factor: CGFloat) -> CGSize {
    return CGSize(width: width/factor, height: height/factor)
  }
  
  var length: CGFloat {
    return sqrt(pow(width, 2) + pow(height, 2))
  }
  
  var inverted: CGSize {
    return CGSize(width: -width, height: -height)
  }
}

extension CGPoint {
  func translatedBy(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: self.x + x, y: self.y + y)
  }
}

extension CGPoint {
  func alignCenterInParent(_ parent: CGSize) -> CGPoint {
    let x = parent.width/2 + self.x
    let y = parent.height/2 + self.y
    return CGPoint(x: x, y: y)
  }
  
  func scaledFrom(_ factor: CGFloat) -> CGPoint {
    return CGPoint(
      x: self.x * factor,
      y: self.y * factor)
  }
}


extension Array {
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Date {
    func simpleDateString()-> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }
}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension String {
   func convertToValidFileName() -> String {
       var invalidCharacters = CharacterSet(charactersIn: ":/")
       invalidCharacters.formUnion(.newlines)
       invalidCharacters.formUnion(.illegalCharacters)
       invalidCharacters.formUnion(.controlCharacters)

       let newFilename = self
           .components(separatedBy: invalidCharacters)
           .joined(separator: "-")
       
       return newFilename
   }
}

extension CGKeyCode
{
    static let kVK_Option     : CGKeyCode = 0x3A
    static let kVK_RightOption: CGKeyCode = 0x3D
    
    var isPressed: Bool {
        CGEventSource.keyState(.combinedSessionState, key: self)
    }
    
    static var optionKeyPressed: Bool {
        return Self.kVK_Option.isPressed || Self.kVK_RightOption.isPressed
    }
}

extension Color {

    var components: (r: Double, g: Double, b: Double, o: Double) {
        var nsColor: NSColor
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        if self.description.contains("NamedColor") {
            let lowerBound = self.description.range(of: "name: \"")!.upperBound
            let upperBound = self.description.range(of: "\", bundle")!.lowerBound
            let assetsName = String(self.description[lowerBound..<upperBound])
            let tempColor = NSColor(named: assetsName)!
            nsColor = tempColor.usingColorSpace(NSColorSpace.sRGB) ?? NSColor.white
        } else {
            let tempColor = NSColor(self)
            nsColor = tempColor.usingColorSpace(NSColorSpace.sRGB) ?? NSColor.white
        }
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &o)
        return (Double(r), Double(g), Double(b), Double(o))
    }
}

struct ConcreteColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
}


struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case opacity
    }
    var color: Color?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let color = color {
            let (fgr, fgg, fgb, fgo) = color.components
            let temp = ConcreteColor(red: fgr, green: fgg, blue: fgb, opacity: fgo)
            try container.encode(temp)
        } else {
            let temp = ConcreteColor(red: red, green: green, blue: blue, opacity: opacity)
            try container.encode(temp)
        }
    }
    
    init(color: Color) {
        self.color = color
        (red, green, blue, opacity) = color.components
    }
    
    init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    init(from decoder: Decoder) throws {
        if let temp = try? decoder.singleValueContainer().decode(ConcreteColor.self) {
            self.red = temp.red
            self.green = temp.green
            self.blue = temp.blue
            self.opacity = temp.opacity
            self.color = Color(.sRGB, red: temp.red, green: temp.green, blue: temp.blue, opacity: temp.opacity)
            return
        }
        throw CC.messedUp
    }
    
    enum CC: Error {
        case messedUp
    }
}

enum IntOrString {
    case int(Int)
    case string(String)
}


extension IntOrString: Codable {
    
    enum CodingKeys: String, CodingKey {
        case int
        case string
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let num):
            try container.encode(num)
        case .string(let str):
            try container.encode(str)
        }
    }
    
    init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        throw IntOrString.missingValue
    }
    
    var description : String {
        get {
            switch self {
            case .int(let num):
                return num.description
            case .string(let str):
                return str
            }
        }
    }
    
    var asString: String {
        get {
            switch self {
            case .int(let num):
                return num.description
            case .string(let str):
                return str
            }
        }
    }
    
    var asInt: Int {
        get {
            switch self {
            case .int(let num):
                return num
            case .string(let str):
                return Int(str) ?? 0
            }
        }
    }
    
    enum IntOrString:Error {
        case missingValue
    }
}

