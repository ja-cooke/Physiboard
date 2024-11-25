//
//  AudioController.swift
//
//  Synthesiser Engine for PhysiBoard
//  Creates and controls a simple monophonic FM Synthesiser
//
//  Uses AudioKit 5.2.2, KissFFT 1.0.0 and SoundpipeAudioKit 5.2.2
//
//  Created by Jonathan Cooke on 18/01/2022.
//

import Foundation
import AudioKit
import SoundpipeAudioKit
import CoreGraphics

class AudioController {
    
    //------------------------ Variables and Constants ------------------------
    
    // AudioUnit Objects
    var engine = AudioEngine()
    var mixer: Mixer!
    var oscFM: FMOscillator!
    var osc = Oscillator(waveform: Table(.sine))
    var reverb : Reverb!
    var clipper : Clipper!
    
    /// Oscillator note frequency, initialises at 440Hz
    var frequency : Float = 440
 
    /// Depth of pitch modulation for vibrato
    private var modDepth : Float = 32
    
    /// Duration between updates
    private let frameDuration : Float = 1/60
    
    //------------------------ Audio Set Up ------------------------
    
    /// Sets up a monophonic FM synthesiser with a small amount of reverb and starts the audio engine
    func setUpAudio() {
        
        // Set up the oscillator type
        oscFM = FMOscillator(waveform: Table(.sine))
        
        // Initial Values
        oscFM.baseFrequency = 440
        oscFM.modulatingMultiplier = 2
        oscFM.amplitude = 0.0
        oscFM.start()
        
        // Initialise a subtle but audible reverb
        reverb = Reverb(oscFM)
        reverb.dryWetMix = 0.2
        
        // Mixer used to set final output volume
        mixer = Mixer(reverb)
        mixer.volume = 0.8
        
        // Connect the FM synth to the audio output
        engine.output = mixer
        try! engine.start() // Enable audio
    }
    
    //--------------------------------------------------------------------------
    //------------------------------ Audio Updates -----------------------------
    //--------------------------------------------------------------------------
    
    /// Changes the amount of vibrato on the FM synthesiser
    func updatePitchModDepth(anchorPosition : Float) {
        modDepth = exp(log(128)*anchorPosition)
    }
    
    /// Matches the FM synth vibrato to the rotation angle of a physicsBox
    func updatePitchMod(boxRotation: CGFloat) {
        if oscFM != nil {
            // Transforms the box rotation to vibrato oscillations
            // A continuous rotation will transform to a triangle wave
            let vibratoPosition = (abs(Float(boxRotation))-Float.pi/2)
            
            // Set the FM carrier frequency to the note frequency plus vibrato amount
            oscFM.baseFrequency = frequency + vibratoPosition  * modDepth
        }
    }
    
    /// Ramps the output volume of the FM synthesiser to a new value.
    /// Choose volume values between 0 and 1.
    func updateAmpEnvelope(volume: Float) {
        oscFM.$amplitude.ramp(to: volume, duration: frameDuration)
    }
    
    /// Ramps the output volume of the FM synthesiser to a new value.
    func updateFMAmplitude(fmAmplitude: Float) {
        oscFM.$modulationIndex.ramp(to: (fmAmplitude)/oscFM.modulatingMultiplier/oscFM.baseFrequency, duration: frameDuration)
    }
    
    /// Changes the note played by the FM synthesiser
    func changeOscFreq(frequency:Float) {
        self.frequency = frequency
    }
    
    /// Controls FM synth note on and off amplitude envelope behaviours.
    func playState(isKeyboardTouched keyboardIsTouched: Bool) {
        let attackTime : Float = 0.05
        let releaseTime : Float = 0.5
        let sustainAmplitude : Float = 0.2
        let releaseAmplitude : Float = 0
        
        if keyboardIsTouched {
            oscFM.$amplitude.ramp(to: sustainAmplitude, duration: attackTime)
        }
        else {
            oscFM.$amplitude.ramp(to: releaseAmplitude, duration: releaseTime)
        }
    }
    
    /// Step the FM modulator frequency multiplier up or down. Accepts Strings "Up" and "Down" as arguments.
    func changeFMModMultiplier(change: String) {
        // Changes the FM modulating frequency multiplier up or down in discrete steps
        // Steps increase in size for larger multiplier values
        // For values below 1 the multiplier is doubled or halved
        
        // Define the ranges within which different step sizes are used
        let multiplierUpperLimit : AUValue = 16
        let multiplierLowerLimit : AUValue = 0.01
        let multiplierUpperRange : AUValue = 10
        let multiplierMidRange : AUValue = 1
        
        // Define the steps or multiples used in the defined ranges
        let midRangeStep : AUValue = 1
        let upperRangeStep : AUValue = 2
        let lowerRangeStep : AUValue = -1
        let upperRangeMultiplier : AUValue = 2
        let lowerRangeMultiplier : AUValue = 0.5
        
        // Store the frequency multiplier in a temporary variable for readability
        var modMult : AUValue = oscFM.modulatingMultiplier
        
        // Work out the next value of the frequency multiplier with a step up or down
        switch change {
        case "Up":
            if modMult >= multiplierMidRange {
                modMult += midRangeStep
            }
            else if modMult >= multiplierUpperRange && modMult < multiplierUpperLimit {
                modMult += upperRangeStep
            }
            else if modMult < multiplierMidRange {
                modMult = modMult * upperRangeMultiplier
            }
        case "Down":
            if modMult > multiplierMidRange {
                modMult += lowerRangeStep
            }
            else if modMult <= multiplierMidRange && modMult > multiplierLowerLimit {
                modMult = modMult * lowerRangeMultiplier
            }
        default: break
        }
        
        // Set the FM modulating frequency multiplier to the new value
        oscFM.modulatingMultiplier = modMult
    }
}

