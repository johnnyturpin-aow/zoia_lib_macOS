/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation


// TODO: This needs revisiting - Surely a generic processor for this can be created?

// case list created by parsing
enum ZoiaModuleProcessor: Int {
    case sv_filter = 0
    case audio_input = 1
    case audio_output = 2
    case aliaser = 3
    case sequencer = 4
    case lfo = 5
    case adsr = 6
    case vca = 7
    case audio_multiply = 8
    case bit_crusher = 9
    case sample_and_hold = 10
    case od_and_distortion = 11
    case env_follower = 12
    case delay_line = 13
    case oscillator = 14
    case pushbutton = 15
    case keyboard = 16
    case cv_invert = 17
    case steps = 18
    case slew_limiter = 19
    case midi_notes_in = 20
    case midi_cc_in = 21
    case multiplier = 22
    case compressor = 23
    case multi_filter = 24
    case plate_reverb = 25
    case buffer_delay = 26
    case all_pass_filter = 27
    case quantizer = 28
    case phaser = 29
    case looper = 30
    case in_switch = 31
    case out_switch = 32
    case audio_in_switch = 33
    case audio_out_switch = 34
    case midi_pressure = 35
    case onset_detector = 36
    case rhythm = 37
    case noise = 38
    case random = 39
    case gate = 40
    case tremolo = 41
    case tone_control = 42
    case delay_w_mod = 43
    case stompswitch = 44
    case value = 45
    case cv_delay = 46
    case cv_loop = 47
    case cv_filter = 48
    case clock_divider = 49
    case comparator = 50
    case cv_rectify = 51
    case trigger = 52
    case stereo_spread = 53
    case cport_exp_cv_in = 54
    case cport_cv_out = 55
    case ui_button = 56
    case audio_panner = 57
    case pitch_detector = 58
    case pitch_shifter = 59
    case midi_note_out = 60
    case midi_cc_out = 61
    case midi_pc_out = 62
    case bit_modulator = 63
    case audio_balance = 64
    case inverter = 65
    case fuzz = 66
    case ghostverb = 67
    case cabinet_sim = 68
    case flanger = 69
    case chorus = 70
    case vibrato = 71
    case env_filter = 72
    case ring_modulator = 73
    case hall_reverb = 74
    case ping_pong_delay = 75
    case audio_mixer = 76
    case cv_flip_flop = 77
    case diffuser = 78
    case reverb_lite = 79
    case room_reverb = 80
    case pixel = 81
    case midi_clock_in = 82
    case granular = 83
    case midi_clock_out = 84
    case tap_to_cv = 85
    case midi_pitch_bend_in = 86
    case euro_cv_out_4 = 87
    case euro_cv_in_1 = 88
    case euro_cv_in_2 = 89
    case euro_cv_in_3 = 90
    case euro_cv_in_4 = 91
    case euro_headphone_amp = 92
    case euro_audio_input_1 = 93
    case euro_audio_input_2 = 94
    case euro_audio_output_1 = 95
    case euro_audio_output_2 = 96
    case euro_pushbutton_1 = 97
    case euro_pushbutton_2 = 98
    case euro_cv_out_1 = 99
    case euro_cv_out_2 = 100
    case euro_cv_out_3 = 101
    case sampler = 102
    case device_control = 103
    case cv_mixer = 104
	case logic_gate = 105
	case reverse_delay = 106
	case univibe = 107

    func calculate_blocks_in_module(module: ParsedBinaryPatch.Module) -> [ModuleBlock] {
        var blocks: [ModuleBlock] = []
        
        let referenceModules = EmpressReference.shared.moduleList
        guard let ref_module = referenceModules[self.rawValue.description] else { return blocks }
        guard let ver = module.version else { return blocks }
        let min_blocks = referenceModules[self.rawValue.description]?.min_blocks ?? 0
        let max_blocks = referenceModules[self.rawValue.description]?.max_blocks ?? 0
        let d = ref_module.blocks
        
        switch self.rawValue {
            
        case 0: //.sv_filter
            blocks = [d[0], d[1], d[2]]
            for (key,value) in module.options {
                if value.description == "on" {
                    if let foundBlock = d.first(where: { $0.keys.first == key }) {
                        blocks.append(foundBlock)
                    }
                }
            }
            
            
        case 1: //.audio_input
            blocks = []
            switch module.options.first(where: { $0.key == "channels"})?.value.asString {
            case "left":
                blocks = [d[0]]
            case "right":
                blocks = [d[1]]
            default:
                blocks = [d[0], d[1]]
            }
            
        case 2: //.audio_output
            blocks = []
            switch module.options.first(where: { $0.key == "channels"} )?.value.asString {
            case "left":
                blocks = [d[0]]
            case "right":
                blocks = [d[1]]
            default:
                blocks = [d[0], d[1]]
            }
            
            switch module.options.first(where: { $0.key == "gain_control" })?.value.asString {
            case "on":
                blocks.append(d[2])
            default:
                break
            }
			
		// options
		// [0] = number_of_steps
		// [1] = num_of_tracks
		// [2] = restart_jack
		// [3] = behavior
		// [4] = key_input
		// [5] = number_of_pages
            
        case 4: //.sequencer
            blocks = []
            if let num_of_steps = module.options.first(where: { $0.key == "number_of_steps"} )?.value.asInt {
                for i in 1...num_of_steps {
                    blocks.append(d[i - 1])
                }
                blocks.append(d[32])
            }
            
            if module.options.first(where: { $0.key == "restart_jack" })?.value.asString == "on" {
                blocks.append(d[33])
            }
			
			// updated for firmware 5.x sequencer
			/*
			 if opt[4][1] != "off":
				 blocks.append(d[34])
				 blocks.append(d[35])
			 */
			if module.options.first(where: { $0.key == "key_input" })?.value.asString != "off" {
				blocks.append(d[34])
				blocks.append(d[35])
			}
            
            if let num_of_tracks = module.options.first(where: { $0.key == "number_of_tracks"} )?.value.asInt {
                for i in 1...num_of_tracks {
                    blocks.append(d[i + 35])
                }
            }
            
        case 5: //.lfo
            blocks = []
            switch module.options.first(where: { $0.key == "input" })?.value.asString {
            case "tap":
                blocks.append(d[0])
            default:
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "swing_control" })?.value.asString == "on" {
                blocks.append(d[2])
            }
            if module.options.first(where: { $0.key == "phase_input" })?.value.asString == "on" {
                blocks.append(d[3])
            }
            if module.options.first(where: { $0.key == "phase_reset" })?.value.asString == "on" {
                blocks.append(d[4])
            }
            blocks.append(d[5])
            
            
        case 6: //.adsr
            blocks = [d[0]]
            

            if module.options.first(where: { $0.key == "retrigger_input" })?.value.asString == "on" {
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "initial_delay" })?.value.asString == "on" {
                blocks.append(d[2])
            }
            blocks.append(d[3])
            if module.options.first(where: { $0.key == "str" })?.value.asString == "on" {
                blocks.append(d[6])
            }
            if module.options.first(where: { $0.key == "hold_sustain_release" })?.value.asString == "on" {
                blocks.append(d[7])
            }
            if module.options.first(where: { $0.key == "str" })?.value.asString == "on" {
                blocks.append(d[8])
            }
            blocks.append(d[9])
            
        case 7: //.vca
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[4])
            }
            
            
        case 12: //.env_follower
            blocks = [d[0]]

            if module.options.first(where: { $0.key == "rise_fall_time" })?.value.asString == "on" {
                blocks.append(d[1])
                blocks.append(d[2])
            }
            blocks.append(d[3])
            
            
        case 13: //.delay_line
            blocks = [d[0]]
            
            switch module.options.first(where: { $0.key == "tap_tempo_in" })?.value.asString {
            case "yes":
                blocks.append(d[2])
                blocks.append(d[3])
            default:
                blocks.append(d[1])
                
            }
            blocks.append(d[4])
            
        case 14: //.oscillator
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "fm_in" })?.value.asString == "on" {
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "duty_cycle" })?.value.asString == "on" {
                blocks.append(d[2])
            }
            blocks.append(d[3])
            
            
        case 16: //.keyboard
            blocks = []
            if let num_of_notes = module.options.first(where: { $0.key == "#_of_notes"} )?.value.asInt {
                for i in 1...num_of_notes {
                    blocks.append(d[i - 1])
                }
                blocks.append(d[32])
            }
            blocks.append(d[40])
            blocks.append(d[41])
            blocks.append(d[42])
            
            
        case 19:
            blocks = [d[0]]
            
            switch module.options.first?.value.asString {
            case "linked":
                blocks.append(d[1])
            default:
                blocks.append(d[2])
                blocks.append(d[3])
            }
            blocks.append(d[4])
            
        case 20:
            blocks = []
            if let num_of_outputs = module.options.first(where: { $0.key == "#_of_outputs"} )?.value.asInt {
                for i in 1...num_of_outputs {
                    blocks.append(d[4 * (i - 1)])
                    blocks.append(d[4 * (i - 1) + 1])
                    if module.options.first(where: { $0.key == "velocity_output" })?.value.asString == "on" {
                        blocks.append(d[4 * (i - 1) + 2])
                    }
                    if module.options.first(where: { $0.key == "trigger_pulse" })?.value.asString == "on" {
                        blocks.append(d[4 * (i - 1) + 3])
                    }
                }
            }
            
        case 22:
            blocks = [d[0]]
            
            let num_inputs = module.options.first?.value.asInt ?? 0
            for i in 2...num_inputs {
                blocks.append(d[i - 1])
            }
            blocks.append(d[8])
            
            
        case 23:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            if module.options.first(where: { $0.key == "attack_ctrl" })?.value.asString == "on" {
                blocks.append(d[3])
            }
            if module.options.first(where: { $0.key == "release_ctrl" })?.value.asString == "on" {
                blocks.append(d[4])
            }
            if module.options.first(where: { $0.key == "ratio_ctrl" })?.value.asString == "on" {
                blocks.append(d[5])
            }
            if module.options.first(where: { $0.key == "sidechain" })?.value.asString == "external" {
                blocks.append(d[6])
            }
            blocks.append(d[7])
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[8])
            }
            
        case 24:
            blocks = [d[0]]
            if let filter_shape = module.options.first?.value.asString {
                if ["bell","hi_shelf","low_shelf"].contains(filter_shape) {
                    blocks.append(d[1])
                }
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            
        case 28:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "key_scale_jacks" })?.value.asString == "yes" {
                blocks.append(d[1])
                blocks.append(d[2])
            }
            blocks.append(d[3])
            
        case 29:
            blocks = [d[0]]

            if module.options.first(where: { $0.key == "channels" })?.value.asString == "2in->2out" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            case "tap_tempo":
                blocks.append(d[3])
            default:
                blocks.append(d[4])
            }
            blocks.append(d[5])
            blocks.append(d[6])
            blocks.append(d[7])
            blocks.append(d[8])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in->1out" {
                blocks.append(d[9])
            }

        case 30:
            blocks = [d[0], d[1], d[2]]
            if module.options.first(where: { $0.key == "stop_play_button" })?.value.asString == "yes" {
                blocks.append(d[3])
            }
            blocks.append(d[4])
            if module.options.first(where: { $0.key == "length_edit" })?.value.asString == "on" {
                blocks.append(d[5])
                blocks.append(d[6])
            }
            if module.options.first(where: { $0.key == "play_reverse" })?.value.asString == "yes" {
                blocks.append(d[7])
            }
            if module.options.first(where: { $0.key == "overdub" })?.value.asString == "yes" {
                blocks.append(d[8])
            }
            blocks.append(d[9])
            
        case 31:
            blocks = []
            let num_inputs = module.options.first?.value.asInt ?? 1
            for i in 1...num_inputs {
                blocks.append(d[i - 1])
            }
            blocks.append(d[16])
            blocks.append(d[17])
            
        case 32:
            blocks = [d[0], d[1]]
            let num_outputs = module.options.first?.value.asInt ?? 1
            for i in 1...num_outputs {
                blocks.append(d[i + 1])
            }
            
            
        case 33:
            blocks = []
            let num_inputs = module.options.first(where: { $0.key == "num_inputs" })?.value.asInt ?? 0
            for i in 1...num_inputs {
                blocks.append(d[i - 1])
            }
            blocks.append(d[16])
            blocks.append(d[17])
            
            
        case 34:
            blocks = [d[0], d[1]]
            let num_outputs = module.options.first(where: { $0.key == "num_outputs" })?.value.asInt ?? 0
            for i in 1...num_outputs {
                blocks.append(d[i + 1])
            }
            
        case 36:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "sensitivity" })?.value.asString == "on" {
                blocks.append(d[1])
            }
            blocks.append(d[2])

        case 37:
            blocks = [d[0], d[1], d[2]]
            if module.options.first(where: { $0.key == "done_ctrl" })?.value.asString == "on" {
                blocks.append(d[3])
            }
            blocks.append(d[4])
    
        case 39:
            blocks = []
            if module.options.first(where: { $0.key == "new_val_on_trig" })?.value.asString == "on" {
                blocks.append(d[0])
            }
            blocks.append(d[1])
            
            
        case 40:
            blocks = [d[0]]

            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])

            if module.options.first(where: { $0.key == "attack_ctrl" })?.value.asString == "on" {
                blocks.append(d[3])
            }
            if module.options.first(where: { $0.key == "release_ctrl" })?.value.asString == "on" {
                blocks.append(d[4])
            }
            if module.options.first(where: { $0.key == "sidechain" })?.value.asString == "external" {
                blocks.append(d[5])
            }
            blocks.append(d[6])
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[7])
            }
            
            
        case 41:
            blocks = [d[0]]

            if module.options.first(where: { $0.key == "channels" })?.value.asString == "2in->2out" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            case "tap_tempo":
                blocks.append(d[3])
            default:
                blocks.append(d[4])
            }
            blocks.append(d[5])
            blocks.append(d[6])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in-1out" {
                blocks.append(d[7])
            }
            
        case 42:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            if module.options.first(where: { $0.key == "num_mid_bands" })?.value.asInt == 2 {
                blocks.append(d[5])
                blocks.append(d[6])
                
            }
            blocks.append(d[7])
            blocks.append(d[8])
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[9])
            }
            
        case 43:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "2in->2out" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            default:
                blocks.append(d[3])
            }
            blocks.append(d[4])
            blocks.append(d[5])
            blocks.append(d[6])
            blocks.append(d[7])
            blocks.append(d[8])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in->1out" {
                blocks.append(d[9])
            }
            
        case 47:
            blocks = [d[0], d[1], d[2], d[3]]
            if module.options.first(where: { $0.key == "length_edit" })?.value.asString == "on" {
                blocks.append(d[4])
                blocks.append(d[5])
            }
            blocks.append(d[6])
            blocks.append(d[7])
            
            
            
        case 48:
            blocks = [d[0]]
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "linked":
                blocks.append(d[1])
            default:
                blocks.append(d[2])
                blocks.append(d[3])
            }
            blocks.append(d[4])
            
            
        case 49:
            if ver >= 1 {
                blocks = [d[0], d[1], d[3], d[4], d[5]]
            } else {
                blocks = [d[0], d[1], d[2], d[5]]
            }
            
        case 53:
            if module.options.first?.value.asString == "haas" {
                blocks = [d[0], d[3], d[4], d[5]]
            } else {
                blocks = [d[0], d[1], d[2], d[4], d[5]]
            }
            
            
        case 56:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "cv_output" })?.value.asString == "enabled" {
                blocks.append(d[1])
            }
            
        case 57:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "2in->2out" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            
        case 60:
            blocks = [d[0], d[1]]
            if module.options.first(where: { $0.key == "velocity_output" })?.value.asString == "on" {
                blocks.append(d[2])
            }
            
        case 64:
            
            if module.options.first(where: { $0.key == "stereo" })?.value.asString == "mono" {
                blocks = [d[0], d[2], d[4], d[5]]
            } else {
                blocks = d
            }
            
        case 67:
            blocks = [d[0]]
            if module.options.first?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            blocks.append(d[5])
            blocks.append(d[6])
            if module.options.first?.value.asString != "1in>1out" {
                blocks.append(d[7])
            }
            
        case 68:
            
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "mono" {
                blocks = [d[0], d[2]]
            } else {
                blocks = d
            }
            
        case 69:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            case "tap_tempo":
                blocks.append(d[3])
            default:
                blocks.append(d[4])
            }
            blocks.append(d[5])
            blocks.append(d[6])
            blocks.append(d[7])
            blocks.append(d[8])
            blocks.append(d[9])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in>1out" {
                blocks.append(d[10])
            }
            
        case 70:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            case "tap_tempo":
                blocks.append(d[3])
            default:
                blocks.append(d[4])
            }
            blocks.append(d[5])
            blocks.append(d[6])
            blocks.append(d[7])
            blocks.append(d[8])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in>1out" {
                blocks.append(d[9])
            }
            
        case 71:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            switch module.options.first(where: { $0.key == "control" })?.value.asString {
            case "rate":
                blocks.append(d[2])
            case "tap_tempo":
                blocks.append(d[3])
            default:
                blocks.append(d[4])
            }
            blocks.append(d[5])
            blocks.append(d[6])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in>1out" {
                blocks.append(d[7])
            }
            
        case 72:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            blocks.append(d[5])
            blocks.append(d[6])
            if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in>1out" {
                blocks.append(d[7])
            }
            
        case 73:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "ext_audio_in" })?.value.asString == "off" {
                blocks.append(d[1])
            } else {
                blocks.append(d[2])
            }
            if module.options.first(where: { $0.key == "duty_cycle" })?.value.asString == "on" {
                blocks.append(d[3])
            }
            blocks.append(d[4])
            blocks.append(d[5])

        case 75:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "control" })?.value.asString == "rate" {
                blocks.append(d[2])
            } else {
                blocks.append(d[3])
            }
            blocks.append(d[4])
            blocks.append(d[5])
            blocks.append(d[6])
            blocks.append(d[7])
            blocks.append(d[8])
            blocks.append(d[9])
            
        case 76:
            blocks = []
            if let num_channels = module.options.first(where: { $0.key == "channels"} )?.value.asInt {
                for i in 1...num_channels {
                    blocks.append(d[2 * (i - 1)])
                    if module.options.first(where: { $0.key == "stereo" })?.value.asString == "stereo" {
                        blocks.append(d[2 * (i - 1) + 1])
                    }
                }
                for i in 1...num_channels {
                    blocks.append(d[i + 15])
                }
                if module.options.first(where: { $0.key == "panning" })?.value.asString == "on" {
                    for i in 1...num_channels {
                        blocks.append(d[i + 23])
                    }
                }
            }
            blocks.append(d[32])
            if module.options.first(where: { $0.key == "stereo" })?.value.asString == "stereo" {
                blocks.append(d[33])
            }
            
        case 79:
            blocks = [d[0]]
            if module.options.first?.value.asString == "stereo" {
                blocks.append(d[1])
            }
            blocks.append(d[2])
            blocks.append(d[3])
            blocks.append(d[4])
            if module.options.first?.value.asString != "1in->1out" {
                blocks.append(d[5])
            }
            
        case 81:
            if module.options.first?.value.asString == "cv" {
                blocks = [d[0]]
            } else {
                blocks = [d[1]]
            }
            
        case 82:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "clock_out" })?.value.asString == "enabled" {
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "run_out" })?.value.asString == "enabled" {
                blocks.append(d[2])
            }
            if module.options.first(where: { $0.key == "divider" })?.value.asString == "enabled" {
                blocks.append(d[3])
            }
            
        case 83:
            if module.options.first(where: { $0.key == "channels" })?.value.asString == "mono" {
                blocks = [d[0], d[2], d[3], d[4], d[5], d[6], d[7], d[8]]
            } else {
                blocks = d
            }
            
        case 84:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "run_in" })?.value.asString == "enabled" {
                blocks.append(d[1])
            }
            if module.options.first(where: { $0.key == "reset_in" })?.value.asString == "enabled" {
                blocks.append(d[2])
            }
            if module.options.first(where: { $0.key == "position" })?.value.asString == "enabled" {
                blocks.append(d[3])
                blocks.append(d[4])
            }
            
        case 85:
            blocks = [d[0]]
            if module.options.first(where: { $0.key == "range" })?.value.asString == "on" {
                blocks.append(d[1])
                blocks.append(d[2])
            }
            blocks.append(d[3])
            
        case 102:
			blocks = []
			blocks = [d[0]]
			if module.options.first(where: { $0.key == "record" })?.value.asString != "disabled" {
				blocks.append(d[0])
				blocks.append(d[1])
				blocks.append(d[2])
			}
			blocks.append(d[3])
			blocks.append(d[4])
			if module.options.first(where: { $0.key == "reverse_button" })?.value.asString == "on" {
				blocks.append(d[5])
			}
			blocks.append(d[6])
			blocks.append(d[7])
			
			if module.options.first(where: { $0.key == "cv_outputs" })?.value.asString == "on" {
				blocks.append(d[8])
				blocks.append(d[9])
			}
			blocks.append(d[10])
			blocks.append(d[11])
            
        case 103:
            switch module.options.first?.value.asString {
            case "bypass":
                blocks = [d[0]]
            case "stomp aux":
                blocks = [d[1]]
            default:
                blocks = [d[2]]
            }
        case 104:
            blocks = []
            if let num_channels = module.options.first(where: { $0.key == "num_channels"} )?.value.asInt {
                for i in 1...num_channels {
                    blocks.append(d[i - 1])
                }
                for i in 1...num_channels {
                    blocks.append(d[i + 7])
                }
            }
            blocks.append(d[16])
			
		// logic gate
		case 105:
			blocks = [d[0]]
			if module.options.first(where: { $0.key == "operation" })?.value.asString != "NOT" {
				let num_inputs = (module.options.first(where: { $0.key == "num_of_inputs"} )?.value.asInt ?? 2) + 1
				for index in 2..<num_inputs {
					blocks.append(d[index - 1])
				}
				if module.options.first(where: { $0.key == "threshold" })?.value.asString == "on" {
					blocks.append(d[38])
				}
				blocks.append(d[39])
				
			} else {
				if module.options.first(where: { $0.key == "threshold" })?.value.asString == "on" {
					blocks.append(d[38])
				}
				blocks.append(d[39])
			}
			

		// reverse delay
			/*
			 blocks = [d[0]]
			 if opt[0][1] == "stereo":
				 blocks.append(d[1])
			 if opt[1][1] == "rate":
				 blocks.append(d[2])
			 else:
				 blocks.append(d[3])
				 blocks.append(d[4])
			 blocks.append(d[5])
			 blocks.append(d[6])
			 blocks.append(d[7])
			 blocks.append(d[8])
			 if opt[0][1] == "stereo":
				 blocks.append(d[9])
			 */
		case 106:
			blocks = [d[0]]

			if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
				blocks.append(d[1])
			}
			if module.options.first(where: { $0.key == "control" })?.value.asString == "rate" {
				blocks.append(d[2])
			} else {
				blocks.append(d[3])
				blocks.append(d[4])
			}
			blocks.append(d[5])
			blocks.append(d[6])
			blocks.append(d[7])
			blocks.append(d[8])
			if module.options.first(where:  { $0.key == "channels" })?.value.asString == "stereo" {
				blocks.append(d[9])
			}
            
		// Univibe
		/*
		 blocks = [d[0]]
		 if opt[0][1] == "stereo":
			 blocks.append(d[1])
		 if opt[1][1] == "rate":
			 blocks.append(d[2])
		 elif opt[1][1] == "tap_tempo":
			 blocks.append(d[3])
		 else:
			 blocks.append(d[4])
		 blocks.append(d[5])
		 blocks.append(d[6])
		 blocks.append(d[7])
		 blocks.append(d[8])
		 if opt[0][1] != "1in->1out":
			 blocks.append(d[9])
		 */
		case 107:
			blocks = [d[0]]
			if module.options.first(where: { $0.key == "channels" })?.value.asString == "stereo" {
				blocks.append(d[1])
			}
			if module.options.first(where: { $0.key == "control" })?.value.asString == "rate" {
				blocks.append(d[2])
			} else if module.options.first(where: { $0.key == "control" })?.value.asString == "tap_tempo" {
				blocks.append(d[3])
			} else {
				blocks.append(d[4])
			}
			blocks.append(d[5])
			blocks.append(d[6])
			blocks.append(d[7])
			blocks.append(d[8])
			
			if module.options.first(where: { $0.key == "channels" })?.value.asString != "1in->1out" {
				blocks.append(d[9])
			}
        default:
            blocks = d
            
        }
        return blocks
    }
    
}


