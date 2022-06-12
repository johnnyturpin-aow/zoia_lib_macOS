/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation


// TODO: Much work is needed for creation of static test data
struct TestData {
    static func testPatch() -> PatchWrapper {
        return PatchWrapper(patch: PatchStorage.testPatch())
    }
}

extension PatchStorage {
    static func testPatch() -> PatchStorage.Patch {
        
        return Patch(id: 1,
                     selfUrl: "https://patchstorage.com/api/alpha/patches/151317",
                     link: "https://patchstorage.com/transmogrifier-a-highly-customizable-glitchy-granular-looper-delay-thing/",
                     created_at: Date(),
                     updated_at: Date(),
                     slug: "transmogrifier-a-highly-customizable-glitchy-granular-looper-delay-thing",
                     title: "Transmogrifier -- A highly customizable, glitchy, granular, looper delay. Thing",
                     excerpt: "Named in honor of Calvin's famous cardboard box, the Transmogrifier transforms whatever you put into...",
                     content: """
Named in honor of Calvin's famous cardboard box, the Transmogrifier transforms whatever you put into it (mostly into glitchy, pitchy, swirling messes, if this is your thing).  The patch originally began as an attempt to use retriggered loops and envelopes scrubbing the start position to produce pitched playback at the same speed as the input.  And it kind of does that!  But the sound was pretty rough, while the opportunities this sort of granular control of the playback process provided seemed ripe for more experimental ends.  Add in a healthy dose of randomizable options, some probabilistic reversing, and some glitchy pitch jumps, and you've got yourself a stew... I mean, a neat, weird granular delay.
\nThing.\r\n\r\nA quick overview of the process:  stereo pairs of read and record loopers are alternated via a clock (tap tempo or MIDI; if you want to adopt this for Zebu use, the clock page is labeled; replace the stompswitch connection to the LFO on that page with the incoming CV clock).  Since there are two different loop layers, this means eight loopers in total.  The loopers begin playback, but as they playback, their play button is retriggered, based on a division of the clock, produced by a ratcheting sequencer and transformed into triggers.  While the loopers are being retriggered or reset (as I call it in the video), envelopes, tied to the clock via a tap to CV converter, scrub the start position of the loop.  Changing the shape of the envelopes will change how the playback progresses; for instance, an envelope that is entirely attack (rising CV) will cause the playback to mirror the direction of the inputs.  An envelope that is entirely decay (and thus falling CV), on the other hand, will cause the playback to move in reverse, with slices from the end of the loop played first, and those from the beginning of the loop played last.  That's the core of the patch; the rest of the processes simply apply randomization to these parameters or play with the native abilities of loopers to change speed or reverse audio playback.\r\n\r\n
The result is something like a granular module, but the control is more... granular in some ways, with the ability affect different grains (microloops or loop slices) separately, especially with the randomization controls.  You'll see, as I describe those controls, that some affect the patch -per loop cycle- and some affect it -per (playback) reset-.\r\n\r\nThe signal path is stereo throughout.\r\n\r\n
Controls:\r\n\r\nFootswitches:\r\n\r\nLeft stompswitch -- tap tempo (also accepts MIDI clock)\r\n\r\nMiddle stompwitch -- turns the random pitch changes on and off (replicates the button on the front page; more on this below)\r\n\r\nRight stompswitch -- turns the random pan spread changes on and off (replicates the button on the front page; more on this below)\r\n\r\nFront page:\r\n\r\nOn the top row, the first two controls (Pitch 1 and Pitch 2) determine the pitch of the two loop layers.  Because the loops are offset unless phase locked, there are benefits to setting both to the same pitch, depending on what you want to achieve.\r\n\r\nNext to these is the Random Pitch Range control and the Random Pitch button.  When the random pitch option is engaged, pitch is randomed -per reset-.  The pitch range controls the probability of a random pitch being introduced.  At 0, no random pitch will be produced.  As you increase the value, octave shifts up and down will be introduced, until at .5, the chances are equal that the pitch will be one of +1 octave, no change, or -1 octave.  Beyond this, pitch changes of plus or minus a fifth are introduced until at 1, there is an equal likelihood that any of these pitch options will be selected.  (These pitches are added to the values set by Pitch 1 and Pitch 2, so if Pitch 1 is set to +1 octave, that loop layer may jump to +2 octaves or back to no pitch change, for instance.)  I like setting the control rather low, at ~.1, so that the majority of the pitches reflect the values set by Pitch 1 and Pitch 2, with a little flavor thrown into the mix.\r\n\r\n
The final control on this row is the Loop Regen control.  This determines how much the loops' outputs is sent to their inputs, producing a delay-like effect.  (I say delay-like as the regeneration will be processed once again by whatever is applied to the loops and more and more artifacts are likely to be produced in these \"echoes.\")  The loops are cross-fed, so the output of loop layer 1 goes into loop layer 2 and vice versa.  This allows for some interesting effects:  for instance, if Pitch 1 is set to an octave below, and Pitch 2 is set to an octave above, the echoes will alternate between playing back at those pitches and playing back at the original pitch of the input signal (as one loop layer counteracts the pitch of the other).  For ascending or descending pitches, set both Pitch controls to the same value (or one pitch control to 0, which will delay the results of the ascending or descending pitch).\r\n\r\nThe second row deals with the playback resets, or the resolution of the loops.  The Resolution control determines the number of ratchets applied by the sequencer, between 1 and 50.  The higher the resolution, the more the playback will reflect the movement of the original audio; at the same time, however, this effectively reduces the grain size, so the higher the resolution, the grainier the output, with a more choppy, tremolo-ish result.\r\n\r\n
The resolution can also be randomized -per loop cycle- by pressing the Random Resolution button.  When this is engaged, the resolution control will act as a depth control, setting the upper resolution of the randomization.\r\n\r\nThe final control on this row is a button called Phase Lock.  Normally, the two loop layers are out of phase; this helps cover over the choppiness a little, as one layer will be playing back while the other is reset.  But the loops can also be locked in phase with one another; this will cause the resets to reinforce, which will give the sound a choppier characteristic, but it also allows some of the randomization features to be applied in tandem, for more of a synchronized sound.\r\n\r\nOn the next row is a control called Scrub Direction.  This controls the shape of the envelopes that scrub the start position of the loops.  At 0, the envelopes are all attack and scrub forward; at 1, they are all decay and scrub backward through the start positions.  In between, they will move in one direction, then change course midway through the loop cycle.\r\n\r\nThe Random Scrub button moves the start position randomly, -per reset-, reshuffling the loop.  Its range is governed internally by the resolution setting when applied to forward audio playback; when audio is reserved, the control is more unruly, which can add an interesting layer of hyper glitchiness.\r\n\r\nThe Reverse Chance control sets a probability that the audio will be reversed -per reset-.  At 0, the audio will play forward with each reset, at 1, the audio will play in reverse with each reset.  At points in between, it may play one direction or another, based on a probability gate's outcome.  The two layers' reverse chance is determined individually, so one layer may play forward while another plays in reverse.\r\n\r\n
On the fourth row are controls for panning.  Pan Spread is a positive or negative value and determines how far the two layers are panned to either side.  (Tip:  This is a fun control to employ an expression pedal with.)\r\n\r\nThe Random Pan Spread button (reproduced by the right stompswitch) will randomize the pan settings -per loop cycle-, causing the two voices to bounce around the stereo field.  The Pan Spread control will act as a depth control, setting the furthest limit of the randomized panning.\r\n\r\nOn the bottom row are controls for the effects.  There are Reverb Decay and Reverb Mix controls for setting the reverb lite; this can be used to wash out your glitches entirely or add a hint of air (or be entirely mixed out, if you want to employ a different reverb in your signal path).  There is a Tone control; this applies a low-pass filter between the loops and the reverb; it can be especially useful for mellowing out some of the harshness/pitchiness of pitched up sounds.  Finally, there are Dry Level and Wet Level controls, which can be employed to set a mix for the patch.  The wet level can go a bit above unity, because of the filtering and other factors that can make it seem less loud than it is.\r\n\r\nIt sounds like a lot, but honestly, I think you'll get good results if you just mess around with controls and press buttons (as long as you think weird, glitchy delays are a good thing; if not, you'll probably get bad results, no matter what buttons you press).
""",
                     files: nil,
                     artwork: Artwork(url: "https://patchstorage.com/wp-content/uploads/2022/04/20220412_064431fgh-1024x461.jpg"),
                     revision: "1.0",
                     preview_url: "https://youtu.be/gMkF9iHTJ34",
                     comment_count: 1,
                     view_count: 135,
                     like_count: 5,
                     download_count: 298,
                     author: PatchStorage.GenericObject(id: 2953, slug: "christopher-h-m-jacques", name: "Christopher H. M. Jacques", description: nil),
                     categories: [GenericObject(id: 77, slug: "effect", name: "Effect", description: nil), GenericObject(id: 177, slug: "utility", name: "Utility", description: nil)],
                     tags: [GenericObject(id: 130, slug: "delay", name: "delay", description: nil), GenericObject(id: 2511, slug: "flanger", name: "flanger", description: nil), GenericObject(id: 232, slug: "reverb", name: "reverb", description: nil)],
                     platform: nil,
                     state: nil,
                     license: nil,
                     customer_license_text: nil)
    }
}

extension TestData {
    static let patch1 =
"""
[
    {
        "id": 151317,
        "self": "https://patchstorage.com/api/alpha/patches/151317",
        "link": "https://patchstorage.com/cubensis/",
        "created_at": "2022-04-12T11:11:08+00:00",
        "updated_at": "2022-04-12T11:13:13+00:00",
        "slug": "cubensis-v1",
        "title": "Cubensis v1",
        "excerpt": "A stereo multi-effects patch consisting of a flanger (pink), filter(green), delay(aqua), reverb (blue), and tremolo(orange)....",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/20220412_064431fgh-1024x461.jpg"
        },
        "comment_count": 0,
        "view_count": 135,
        "like_count": 2,
        "download_count": 16,
        "author": {
            "id": 9587,
            "slug": "daniel_bertola",
            "name": "Daniel_Bertola"
        },
        "categories": [
            {
                "id": 77,
                "name": "Effect",
                "slug": "effect"
            },
            {
                "id": 117,
                "name": "Utility",
                "slug": "utility"
            }
        ],
        "tags": [
            {
                "id": 7759,
                "name": "cubensis",
                "slug": "cubensis"
            },
            {
                "id": 130,
                "name": "delay",
                "slug": "delay"
            },
            {
                "id": 34,
                "name": "filter",
                "slug": "filter"
            },
            {
                "id": 2511,
                "name": "flanger",
                "slug": "flanger"
            },
            {
                "id": 607,
                "name": "multi",
                "slug": "multi"
            },
            {
                "id": 232,
                "name": "reverb",
                "slug": "reverb"
            },
            {
                "id": 21,
                "name": "tremolo",
                "slug": "tremolo"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 150,
            "name": "Work in Progress",
            "slug": "work-in-progress"
        }
    },
    {
        "id": 151290,
        "self": "https://patchstorage.com/api/alpha/patches/151290",
        "link": "https://patchstorage.com/space-echoer/",
        "created_at": "2022-04-11T03:02:01+00:00",
        "updated_at": "2022-04-11T03:02:01+00:00",
        "slug": "space-echoer",
        "title": "Space Echoer",
        "excerpt": "Space Echo-ish, with 3 delay lines, a reverb and input drive.",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/Aina-Solutions-Zoia-Image-1024x582.jpg"
        },
        "comment_count": 0,
        "view_count": 128,
        "like_count": 0,
        "download_count": 28,
        "author": {
            "id": 9507,
            "slug": "albrec",
            "name": "Albrec"
        },
        "categories": [
            {
                "id": 77,
                "name": "Effect",
                "slug": "effect"
            }
        ],
        "tags": [
            {
                "id": 231,
                "name": "multi-effect",
                "slug": "multi-effect"
            },
            {
                "id": 3378,
                "name": "multi-tap",
                "slug": "multi-tap"
            },
            {
                "id": 1158,
                "name": "overdrive",
                "slug": "overdrive"
            },
            {
                "id": 232,
                "name": "reverb",
                "slug": "reverb"
            },
            {
                "id": 3054,
                "name": "tape-delay",
                "slug": "tape-delay"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151287,
        "self": "https://patchstorage.com/api/alpha/patches/151287",
        "link": "https://patchstorage.com/roadside-picnic-a-dark-eerie-drone-synthesizer/",
        "created_at": "2022-04-10T23:59:04+00:00",
        "updated_at": "2022-04-10T23:59:04+00:00",
        "slug": "roadside-picnic-a-dark-eerie-drone-synthesizer",
        "title": "Roadside picnic -- a dark, eerie drone synthesizer",
        "excerpt": "Roadside picnic employs a ring networks of FM to produce eerie, dark drones and soundscapes....",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/ZoiaholeA-1-1024x737.jpg"
        },
        "comment_count": 0,
        "view_count": 111,
        "like_count": 0,
        "download_count": 34,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 4522,
                "name": "cinematic",
                "slug": "cinematic"
            },
            {
                "id": 436,
                "name": "drone",
                "slug": "drone"
            },
            {
                "id": 3975,
                "name": "eerie",
                "slug": "eerie"
            },
            {
                "id": 81,
                "name": "fm",
                "slug": "fm"
            },
            {
                "id": 760,
                "name": "sound-design",
                "slug": "sound-design"
            },
            {
                "id": 586,
                "name": "soundscape",
                "slug": "soundscape"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151243,
        "self": "https://patchstorage.com/api/alpha/patches/151243",
        "link": "https://patchstorage.com/critical-success-a-dice-rolling-patch/",
        "created_at": "2022-04-09T11:47:51+00:00",
        "updated_at": "2022-04-09T11:47:51+00:00",
        "slug": "critical-success-a-dice-rolling-patch",
        "title": "Critical Success -- a dice-rolling patch",
        "excerpt": "Critical Success asks the question: why bring cheap, plastic dice to your game night, when...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/ZoiaholeA-1024x737.jpg"
        },
        "comment_count": 0,
        "view_count": 133,
        "like_count": 2,
        "download_count": 26,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 3317,
                "name": "Game",
                "slug": "game"
            },
            {
                "id": 117,
                "name": "Utility",
                "slug": "utility"
            }
        ],
        "tags": [
            {
                "id": 7754,
                "name": "dice-rolling",
                "slug": "dice-rolling"
            },
            {
                "id": 4398,
                "name": "pixel-art",
                "slug": "pixel-art"
            },
            {
                "id": 7756,
                "name": "rng",
                "slug": "rng"
            },
            {
                "id": 7755,
                "name": "very-necessary",
                "slug": "very-necessary"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151187,
        "self": "https://patchstorage.com/api/alpha/patches/151187",
        "link": "https://patchstorage.com/tape-piece-generative-patch-from-my-april-5th-livestream/",
        "created_at": "2022-04-06T15:20:58+00:00",
        "updated_at": "2022-04-06T15:20:58+00:00",
        "slug": "tape-piece-generative-patch-from-my-april-5th-livestream",
        "title": "Tape piece -- generative patch from my April 5th livestream",
        "excerpt": "Another off-schedule stream. I don't think this is going to become a habit. But I...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/Livestream040522.jpg"
        },
        "comment_count": 0,
        "view_count": 152,
        "like_count": 4,
        "download_count": 44,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 514,
                "name": "generative",
                "slug": "generative"
            },
            {
                "id": 2963,
                "name": "livestream",
                "slug": "livestream"
            },
            {
                "id": 7746,
                "name": "no-tapes-harmed",
                "slug": "no-tapes-harmed"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151147,
        "self": "https://patchstorage.com/api/alpha/patches/151147",
        "link": "https://patchstorage.com/modal-fun-the-patch-from-my-modal-synthesis-tutorial/",
        "created_at": "2022-04-04T17:44:40+00:00",
        "updated_at": "2022-04-04T17:44:40+00:00",
        "slug": "modal-fun-the-patch-from-my-modal-synthesis-tutorial",
        "title": "Modal fun -- the patch from my modal synthesis tutorial",
        "excerpt": "Modal synthesis is one of the most common synthesis methods employed in physical modeling --...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/Zynth-zekrets-modal.png"
        },
        "comment_count": 0,
        "view_count": 170,
        "like_count": 1,
        "download_count": 51,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 750,
                "name": "modal-synthesis",
                "slug": "modal-synthesis"
            },
            {
                "id": 262,
                "name": "tutorial",
                "slug": "tutorial"
            },
            {
                "id": 7727,
                "name": "zynth-zecrets",
                "slug": "zynth-zecrets"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151136,
        "self": "https://patchstorage.com/api/alpha/patches/151136",
        "link": "https://patchstorage.com/snowfall-an-attempt-in-recreating-the-eqd-avalanche-run/",
        "created_at": "2022-04-04T15:01:02+00:00",
        "updated_at": "2022-04-04T15:01:02+00:00",
        "slug": "snowfall-an-attempt-in-recreating-the-eqd-avalanche-run",
        "title": "Snowfall (an attempt in recreating the EQD Avalanche Run)",
        "excerpt": "Hey there, I believe some of you might have seen the old patch on here...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/10009127.jpeg"
        },
        "comment_count": 0,
        "view_count": 266,
        "like_count": 2,
        "download_count": 89,
        "author": {
            "id": 9540,
            "slug": "wazuhk",
            "name": "wazuhk"
        },
        "categories": [
            {
                "id": 77,
                "name": "Effect",
                "slug": "effect"
            }
        ],
        "tags": [
            {
                "id": 7743,
                "name": "avalanche",
                "slug": "avalanche"
            },
            {
                "id": 130,
                "name": "delay",
                "slug": "delay"
            },
            {
                "id": 7745,
                "name": "earthquakerdevices",
                "slug": "earthquakerdevices"
            },
            {
                "id": 7742,
                "name": "eqd",
                "slug": "eqd"
            },
            {
                "id": 232,
                "name": "reverb",
                "slug": "reverb"
            },
            {
                "id": 7744,
                "name": "run",
                "slug": "run"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151121,
        "self": "https://patchstorage.com/api/alpha/patches/151121",
        "link": "https://patchstorage.com/autosite-generative-patch-from-my-march-30th-livestream/",
        "created_at": "2022-04-03T21:41:56+00:00",
        "updated_at": "2022-04-03T21:41:56+00:00",
        "slug": "autosite-generative-patch-from-my-march-30th-livestream",
        "title": "Autosite -- generative patch from my March 30th livestream",
        "excerpt": "This patch began with a bad idea. (Why do I begin patch notes like this?...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/livestream033022.jpg"
        },
        "comment_count": 0,
        "view_count": 113,
        "like_count": 2,
        "download_count": 43,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 514,
                "name": "generative",
                "slug": "generative"
            },
            {
                "id": 2963,
                "name": "livestream",
                "slug": "livestream"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 151095,
        "self": "https://patchstorage.com/api/alpha/patches/151095",
        "link": "https://patchstorage.com/almost-recordable-sequencer-euroburo-version/",
        "created_at": "2022-04-03T12:35:44+00:00",
        "updated_at": "2022-04-03T12:35:44+00:00",
        "slug": "almost-recordable-sequencer-euroburo-version",
        "title": "Almost Recordable Sequencer - Euroburo Version",
        "excerpt": "Empress Zoia / Euroburo Patch: rec seq osc rec seq osc stands for Recordable Sequencer...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/rec_seq_osc-1-1024x580.jpg"
        },
        "comment_count": 0,
        "view_count": 108,
        "like_count": 0,
        "download_count": 33,
        "author": {
            "id": 6100,
            "slug": "playinmyblues",
            "name": "playinmyblues"
        },
        "categories": [
            {
                "id": 76,
                "name": "Sequencer",
                "slug": "sequencer"
            }
        ],
        "tags": [
            {
                "id": 2032,
                "name": "empress",
                "slug": "empress"
            },
            {
                "id": 7359,
                "name": "euroburo",
                "slug": "euroburo"
            },
            {
                "id": 5896,
                "name": "recordable",
                "slug": "recordable"
            },
            {
                "id": 61,
                "name": "sequencer",
                "slug": "sequencer"
            },
            {
                "id": 2689,
                "name": "step",
                "slug": "step"
            },
            {
                "id": 3101,
                "name": "zoia",
                "slug": "zoia"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 150,
            "name": "Work in Progress",
            "slug": "work-in-progress"
        }
    },
    {
        "id": 151092,
        "self": "https://patchstorage.com/api/alpha/patches/151092",
        "link": "https://patchstorage.com/alost-recordable-sequencer-pedal-version/",
        "created_at": "2022-04-03T12:27:02+00:00",
        "updated_at": "2022-04-03T12:27:30+00:00",
        "slug": "almost-recordable-sequencer-pedal-version",
        "title": "Almost Recordable Sequencer - Pedal Version",
        "excerpt": "Empress Zoia / Euroburo Patch: rec seq osc rec seq osc stands for Recordable Sequencer...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/04/rec_seq_osc-1024x580.jpg"
        },
        "comment_count": 0,
        "view_count": 129,
        "like_count": 1,
        "download_count": 37,
        "author": {
            "id": 6100,
            "slug": "playinmyblues",
            "name": "playinmyblues"
        },
        "categories": [
            {
                "id": 76,
                "name": "Sequencer",
                "slug": "sequencer"
            }
        ],
        "tags": [
            {
                "id": 2032,
                "name": "empress",
                "slug": "empress"
            },
            {
                "id": 7359,
                "name": "euroburo",
                "slug": "euroburo"
            },
            {
                "id": 5896,
                "name": "recordable",
                "slug": "recordable"
            },
            {
                "id": 61,
                "name": "sequencer",
                "slug": "sequencer"
            },
            {
                "id": 3101,
                "name": "zoia",
                "slug": "zoia"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 150,
            "name": "Work in Progress",
            "slug": "work-in-progress"
        }
    },
    {
        "id": 151022,
        "self": "https://patchstorage.com/api/alpha/patches/151022",
        "link": "https://patchstorage.com/recordable-sequencer/",
        "created_at": "2022-03-31T00:35:12+00:00",
        "updated_at": "2022-03-31T00:35:12+00:00",
        "slug": "recordable-sequencer",
        "title": "Recordable Sequencer",
        "excerpt": "The intent was to make a recordable sequencer on the Euroburo. I worked at it...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/euroburo.png"
        },
        "comment_count": 1,
        "view_count": 217,
        "like_count": 0,
        "download_count": 45,
        "author": {
            "id": 6100,
            "slug": "playinmyblues",
            "name": "playinmyblues"
        },
        "categories": [
            {
                "id": 76,
                "name": "Sequencer",
                "slug": "sequencer"
            }
        ],
        "tags": [
            {
                "id": 5896,
                "name": "recordable",
                "slug": "recordable"
            },
            {
                "id": 61,
                "name": "sequencer",
                "slug": "sequencer"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 150,
            "name": "Work in Progress",
            "slug": "work-in-progress"
        }
    },
    {
        "id": 151019,
        "self": "https://patchstorage.com/api/alpha/patches/151019",
        "link": "https://patchstorage.com/melodic-looper/",
        "created_at": "2022-03-30T22:10:08+00:00",
        "updated_at": "2022-03-30T22:12:04+00:00",
        "slug": "melodic-looper",
        "title": "Melodic Looper",
        "excerpt": "A looper patch that lets you \"play\" the pitch of the loop melodically via MIDI...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/lupr-1024x586.png"
        },
        "comment_count": 0,
        "view_count": 257,
        "like_count": 3,
        "download_count": 62,
        "author": {
            "id": 9522,
            "slug": "andre-lafosse",
            "name": "andre lafosse"
        },
        "categories": [
            {
                "id": 1,
                "name": "Other",
                "slug": "other"
            },
            {
                "id": 75,
                "name": "Sampler",
                "slug": "sampler"
            }
        ],
        "tags": [
            {
                "id": 6027,
                "name": "live-looping",
                "slug": "live-looping"
            },
            {
                "id": 195,
                "name": "livelooping",
                "slug": "livelooping"
            },
            {
                "id": 7732,
                "name": "livesampling",
                "slug": "livesampling"
            },
            {
                "id": 23,
                "name": "looper",
                "slug": "looper"
            },
            {
                "id": 11,
                "name": "midi",
                "slug": "midi"
            },
            {
                "id": 7734,
                "name": "repitching",
                "slug": "repitching"
            },
            {
                "id": 7733,
                "name": "varispeed",
                "slug": "varispeed"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150991,
        "self": "https://patchstorage.com/api/alpha/patches/150991",
        "link": "https://patchstorage.com/arcade/",
        "created_at": "2022-03-29T22:40:19+00:00",
        "updated_at": "2022-03-30T06:40:26+00:00",
        "slug": "arcade",
        "title": "Arcade",
        "excerpt": "Welcome to the ARCADE, probably the first shooter video game on a guitar pedal! Use...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/ZOIA-Arcade-1024x576.png"
        },
        "comment_count": 1,
        "view_count": 365,
        "like_count": 2,
        "download_count": 79,
        "author": {
            "id": 2979,
            "slug": "wz",
            "name": "WZ"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 3317,
                "name": "Game",
                "slug": "game"
            }
        ],
        "tags": [
            {
                "id": 581,
                "name": "8bit",
                "slug": "8bit"
            },
            {
                "id": 1054,
                "name": "game",
                "slug": "game"
            },
            {
                "id": 369,
                "name": "retro",
                "slug": "retro"
            },
            {
                "id": 839,
                "name": "self-playing",
                "slug": "self-playing"
            },
            {
                "id": 7729,
                "name": "shooter",
                "slug": "shooter"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150982,
        "self": "https://patchstorage.com/api/alpha/patches/150982",
        "link": "https://patchstorage.com/holocaust/",
        "created_at": "2022-03-29T20:40:41+00:00",
        "updated_at": "2022-03-29T20:40:41+00:00",
        "slug": "holocaust",
        "title": "Holocaust",
        "excerpt": "Melancholic, ambient and occasionally abrasive generative synth patch. A memoriam to war victims throughout history....",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/ZOIA-Holocaust-1024x512.jpg"
        },
        "comment_count": 0,
        "view_count": 195,
        "like_count": 1,
        "download_count": 78,
        "author": {
            "id": 2979,
            "slug": "wz",
            "name": "WZ"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 76,
                "name": "Sequencer",
                "slug": "sequencer"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 514,
                "name": "generative",
                "slug": "generative"
            },
            {
                "id": 4688,
                "name": "gloomy",
                "slug": "gloomy"
            },
            {
                "id": 839,
                "name": "self-playing",
                "slug": "self-playing"
            },
            {
                "id": 27,
                "name": "synth",
                "slug": "synth"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150974,
        "self": "https://patchstorage.com/api/alpha/patches/150974",
        "link": "https://patchstorage.com/plinky-plinks-the-patch-from-my-pinged-filters-tutorial/",
        "created_at": "2022-03-29T14:11:04+00:00",
        "updated_at": "2022-03-29T14:11:04+00:00",
        "slug": "plinky-plinks-the-patch-from-my-pinged-filters-tutorial",
        "title": "Plinky plinks -- the patch from my pinged filters tutorial",
        "excerpt": "So, what is a pinged filter? It consists of two elements: an \"exciter\" -- which...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/Zynth-zekrets-pinged-filters.png"
        },
        "comment_count": 0,
        "view_count": 206,
        "like_count": 1,
        "download_count": 85,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 7728,
                "name": "pinged-filters",
                "slug": "pinged-filters"
            },
            {
                "id": 262,
                "name": "tutorial",
                "slug": "tutorial"
            },
            {
                "id": 7727,
                "name": "zynth-zecrets",
                "slug": "zynth-zecrets"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150952,
        "self": "https://patchstorage.com/api/alpha/patches/150952",
        "link": "https://patchstorage.com/decorrelate-a-delay-looper-based-on-shift-registers/",
        "created_at": "2022-03-28T15:20:52+00:00",
        "updated_at": "2022-03-28T15:25:20+00:00",
        "slug": "decorrelate-a-delay-looper-based-on-shift-registers",
        "title": "Decorrelate -- a delay/looper based on shift registers",
        "excerpt": "Decorratete excels at generating unexpected soundscapes, glitchy layers, and all sorts of happy accidents by...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/ZoiaholeA-4-1024x737.jpg"
        },
        "comment_count": 1,
        "view_count": 367,
        "like_count": 4,
        "download_count": 129,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 77,
                "name": "Effect",
                "slug": "effect"
            }
        ],
        "tags": [
            {
                "id": 130,
                "name": "delay",
                "slug": "delay"
            },
            {
                "id": 7271,
                "name": "happy-accidents",
                "slug": "happy-accidents"
            },
            {
                "id": 23,
                "name": "looper",
                "slug": "looper"
            },
            {
                "id": 259,
                "name": "probability",
                "slug": "probability"
            },
            {
                "id": 5070,
                "name": "shift-register",
                "slug": "shift-register"
            },
            {
                "id": 586,
                "name": "soundscape",
                "slug": "soundscape"
            },
            {
                "id": 7725,
                "name": "weird-but-beautiful",
                "slug": "weird-but-beautiful"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150949,
        "self": "https://patchstorage.com/api/alpha/patches/150949",
        "link": "https://patchstorage.com/corlann-generative-patch-from-my-march-26th-livestream/",
        "created_at": "2022-03-28T15:17:16+00:00",
        "updated_at": "2022-03-28T15:17:16+00:00",
        "slug": "corlann-generative-patch-from-my-march-26th-livestream",
        "title": "Corlann -- generative patch from my March 26th livestream",
        "excerpt": "I'm not really sure how this patch came about; sometimes, you just start patching and...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/Livestream032622.jpg"
        },
        "comment_count": 0,
        "view_count": 130,
        "like_count": 1,
        "download_count": 66,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 514,
                "name": "generative",
                "slug": "generative"
            },
            {
                "id": 2963,
                "name": "livestream",
                "slug": "livestream"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150831,
        "self": "https://patchstorage.com/api/alpha/patches/150831",
        "link": "https://patchstorage.com/triple-goddess-an-otherworldly-three-voice-drone-synth/",
        "created_at": "2022-03-23T17:03:31+00:00",
        "updated_at": "2022-03-23T17:03:31+00:00",
        "slug": "triple-goddess-an-otherworldly-three-voice-drone-synth",
        "title": "Triple Goddess -- an otherworldly three-voice drone synth",
        "excerpt": "\"Spells and hymns in Greek magical papyri refer to the goddess (called Hecate, Persephone, and...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/ZoiaholeA-3-1024x737.jpg"
        },
        "comment_count": 0,
        "view_count": 346,
        "like_count": 5,
        "download_count": 122,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 372,
                "name": "Sound",
                "slug": "sound"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 436,
                "name": "drone",
                "slug": "drone"
            },
            {
                "id": 3975,
                "name": "eerie",
                "slug": "eerie"
            },
            {
                "id": 113,
                "name": "ring-mod",
                "slug": "ring-mod"
            },
            {
                "id": 586,
                "name": "soundscape",
                "slug": "soundscape"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150828,
        "self": "https://patchstorage.com/api/alpha/patches/150828",
        "link": "https://patchstorage.com/dark-tides-generative-patch-from-my-march-19th-livestream/",
        "created_at": "2022-03-23T17:00:23+00:00",
        "updated_at": "2022-03-23T17:00:23+00:00",
        "slug": "dark-tides-generative-patch-from-my-march-19th-livestream",
        "title": "Dark tides -- generative patch from my March 19th livestream",
        "excerpt": "For whatever reason, I wasn't feeling it earlier in the week. I started a few...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/Livestream031922.jpg"
        },
        "comment_count": 0,
        "view_count": 190,
        "like_count": 0,
        "download_count": 92,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 378,
                "name": "Composition",
                "slug": "composition"
            },
            {
                "id": 74,
                "name": "Synthesizer",
                "slug": "synthesizer"
            }
        ],
        "tags": [
            {
                "id": 301,
                "name": "ambient",
                "slug": "ambient"
            },
            {
                "id": 235,
                "name": "distortion",
                "slug": "distortion"
            },
            {
                "id": 514,
                "name": "generative",
                "slug": "generative"
            },
            {
                "id": 2963,
                "name": "livestream",
                "slug": "livestream"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    },
    {
        "id": 150678,
        "self": "https://patchstorage.com/api/alpha/patches/150678",
        "link": "https://patchstorage.com/transmogrifier-a-highly-customizable-glitchy-granular-looper-delay-thing/",
        "created_at": "2022-03-17T00:50:20+00:00",
        "updated_at": "2022-03-17T00:50:20+00:00",
        "slug": "transmogrifier-a-highly-customizable-glitchy-granular-looper-delay-thing",
        "title": "Transmogrifier -- a highly customizable, glitchy, granular, looper delay.  Thing.",
        "excerpt": "Named in honor of Calvin's famous cardboard box, the Transmogrifier transforms whatever you put into...",
        "artwork": {
            "url": "https://patchstorage.com/wp-content/uploads/2022/03/ZoiaholeA-2-1024x737.jpg"
        },
        "comment_count": 1,
        "view_count": 924,
        "like_count": 5,
        "download_count": 250,
        "author": {
            "id": 2953,
            "slug": "christopher-h-m-jacques",
            "name": "Christopher H. M. Jacques"
        },
        "categories": [
            {
                "id": 77,
                "name": "Effect",
                "slug": "effect"
            },
            {
                "id": 75,
                "name": "Sampler",
                "slug": "sampler"
            }
        ],
        "tags": [
            {
                "id": 130,
                "name": "delay",
                "slug": "delay"
            },
            {
                "id": 93,
                "name": "granular",
                "slug": "granular"
            },
            {
                "id": 7271,
                "name": "happy-accidents",
                "slug": "happy-accidents"
            },
            {
                "id": 23,
                "name": "looper",
                "slug": "looper"
            },
            {
                "id": 2149,
                "name": "pitch-shifting",
                "slug": "pitch-shifting"
            },
            {
                "id": 5521,
                "name": "randomization",
                "slug": "randomization"
            }
        ],
        "platform": {
            "id": 3003,
            "name": "ZOIA / Euroburo",
            "slug": "zoia"
        },
        "state": {
            "id": 151,
            "name": "Ready to Go",
            "slug": "ready-to-go"
        }
    }
]
"""


}
