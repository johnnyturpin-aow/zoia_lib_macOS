/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation


extension ParsedBinaryPatch.IO {
    
    static func test_io_1() -> ParsedBinaryPatch.IO {
        let io = ParsedBinaryPatch.IO()

        io.audio_input_list[1] = true
        io.audio_input_list[2] = true
        io.audio_output_list[1] = true
        io.audio_output_list[2] = true
        io.stomp_switch[1] = false
        io.stomp_switch[2] = false
        io.stomp_switch[3] = false
        io.cv_in[1] = false
        io.cv_in[2] = false
        io.cv_in[3] = false
        io.cv_in[4] = false
        io.cv_out[1] = false
        io.cv_out[2] = false
        io.cv_out[3] = false
        io.cv_out[4] = false
        io.has_cv = false
        io.has_headphone = false
        io.estimated_cpu = "45.32 %"
        return io
    }
    
    static func test_io_2() -> ParsedBinaryPatch.IO {
        let io = ParsedBinaryPatch.IO()

        io.audio_input_list[1] = true
        io.audio_input_list[2] = false
        io.audio_output_list[1] = true
        io.audio_output_list[2] = true
        io.stomp_switch[1] = false
        io.stomp_switch[2] = false
        io.stomp_switch[3] = false
        io.cv_in[1] = true
        io.cv_in[2] = true
        io.cv_in[3] = false
        io.cv_in[4] = false
        io.cv_out[1] = true
        io.cv_out[2] = true
        io.cv_out[3] = false
        io.cv_out[4] = false
        io.has_cv = true
        io.has_headphone = true
        io.estimated_cpu = "44.87 %"
        return io
    }
    
}

extension ParsedBinaryPatch.Page {
    static func testPage() -> ParsedBinaryPatch.Page {
        return ParsedBinaryPatch.Page(name: "Page 1", index: 0, buttons: TestButtonList.buttons)
    }
    
    
}


struct TestButtonList {
    static let buttons: [PatchButton] =
    [
    PatchButton(buttonColorId: 15, label: "Value", labelWidth: 1), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 01), PatchButton(buttonColorId: 01, label: "Value", labelWidth: 2), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 16),
    PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 09, label: "b2 fb", labelWidth: 1), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 03), PatchButton(buttonColorId: 16),
    PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 10, label: "verby", labelWidth: 1), PatchButton(buttonColorId: 07), PatchButton(buttonColorId: 13, label: "delay", labelWidth: 1), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16),
    PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16),
    PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 01), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 16), PatchButton(buttonColorId: 13), PatchButton(buttonColorId: 13)
    ]
}
