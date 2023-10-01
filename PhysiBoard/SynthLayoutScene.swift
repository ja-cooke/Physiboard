//
//  SynthLayoutScene.swift
//  PhysiBoard
//
//  SpriteKit scene controlling layout, graphics and touch interaction
//  Designed to run in landscape on the iPad (9th Generation)
//
//  Uses AudioKit 5.2.2, KissFFT 1.0.0 and SoundpipeAudioKit 5.2.2
//
//  Created by Jonathan Cooke on 18/01/2023.
//

import SpriteKit
import GameplayKit

import AudioToolbox
import SwiftUI

class SynthLayoutScene: SKScene {
    
    // Useful Constants
    let frameTime: Double = 1/60.0 // the app runs at 60Hz
    let frameTimeReciprocal: Double = 60.0 //  the app runs at 60Hz
    
    // KEYBOARD
    // boundary
    private var keyboardBoundary : SKShapeNode?
    // keyboard objects
    private var key : KeyboardKey!
    private var keyArray : [KeyboardKey] = []
    private var keyboardIsOn = false
    private var keyboardOctave : Int8 = 4
    private var button : KeyboardButton!
    private var buttonArray : [KeyboardButton] = []
    
    // audio
    private var audioController = AudioController()
    
    // PHYSICS OBJECTS
    // boundaries
    private var physicsBoundary : SKShapeNode?
    private let physicsBoundaryScale : Float = 3/4

    // yellow walls
    private var boxDividerA : SKShapeNode!
    private var boxDividerB : SKShapeNode!
    
    // statics
    private var anchorArray : [SKShapeNode] = []
    
    // dynamics
    private var boxArray : [PhysicsBox] = []
    private var numBoxes : Int!
    private var boxSize = CGSize(width: 70, height: 70)
    private var boxPositionArray : [CGPoint] = []
    private var boxColourArray : [UIColor] = []
    private var boxRotatableArray : [Bool] = []
    private var massArray : [CGFloat] = []
    private var circleArray : [Bool] = []

    // joints
    private var springArray : [SKPhysicsJointSpring] = []
    private var sliderArray : [SKPhysicsJointSliding] = []
    private var pinArray : [SKPhysicsJointPin] = []
    
    /// Customised SKShapeNode class with touch behaviours and labels
    private class KeyboardKey : SKShapeNode {
        private var touchState : Bool = false
        
        var label : SKLabelNode?
        
        func setTouchState(touchState: Bool) {
            self.touchState = touchState
        }
        
        func getTouchState() -> Bool {
            return self.touchState
        }
    }
    
    /// Identical to KeyboardKey but named to differentiate for ease
    private class KeyboardButton : KeyboardKey {
    }
    
    /// A physics capable SprikeKit node with trackable touch state. Can be set to be moved or rotated by user touch.
    /// Square by default, but can be set to circular.
    private class PhysicsBox: SKShapeNode {
        var touchState = false
        var rotatable = false
        var circle = false
    }
    
    /// Set up scene layout and initialise audio when the app opens.
    override func didMove(to view: SKView) {
        //------------------------------CREATE SCENE ELEMENTS-----------
        addKeyboard()
        addPhysicsScene()
        
        //------------------------------ INIT AUDIO ENGINE -------------
        audioController.setUpAudio()
    }
    
    //----------------- Custom Functions -----------------------
    
    // -------------------- KEYBOARD ---------------------------
    
    /// Adds a single KeyboardKey node to the scene
    func addKey(position : CGPoint, height : Int, width : Int) {
        // Construct object
        key = KeyboardKey(rectOf: CGSize(width: width, height: height))
        
        // Key visual attributes
        key.lineWidth = 1
        key.fillColor = .white
        key.strokeColor = .lightGray
        key.glowWidth = 0.5
        key.position.x = position.x
        key.position.y = position.y
        
        // Text on the KeyboardKey
        key.label = SKLabelNode(fontNamed: "Arial")
        key.label?.text = "" // Initialise as blank
        key.label?.position = CGPoint(x: position.x, y: position.y-5)
        key.label?.fontColor = .black
        key.label?.fontSize = 18
        
        // Add KeyboardKey and label text to visual scene
        addChild(key)
        addChild(key.label!)
        // Add the key to an array for future reference
        keyArray += [key]
    }
    
    /// Adds a single named KeyboardButton node to the scene
    func addButton(name: String, position: CGPoint, height: Int, width: Int) {
        // Construct object
        button = KeyboardButton(rectOf: CGSize(width: width, height: height))
        
        // Button visual attributes
        button.lineWidth = 1
        button.fillColor = .lightGray
        button.strokeColor = .black
        button.glowWidth = 0.5
        button.position.x = position.x
        button.position.y = position.y
        
        // Text on the button
        button.label = SKLabelNode(fontNamed: "Arial")
        button.label?.text = name
        button.label?.position = CGPoint(x: position.x, y: position.y-5)
        button.label?.fontColor = .black
        button.label?.fontSize = 18
        
        // Add KeyboardButton and label text to visual scene
        addChild(button)
        addChild(button.label!)
        // Add the button to an array for future reference
        buttonArray += [button]
    }
    
    /// Constructs a full two octave keyboard along the bottom edge of the display.
    /// Consists of individual KeyboardKey and KeyboardButton objects.
    func addKeyboard() {
        // Define the area within which the keyboard should sit
        keyboardBoundary = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height * (1-CGFloat(physicsBoundaryScale))))
        
        // Size and position attributes which will be used for placing keys and buttons
        //-----------------------------------------------------------------------------
        let screenSize : CGRect = frame
        
        let screenWidth = Double(screenSize.width)
        let screenHeight = Double(screenSize.height)
        
        let keyboardSize = keyboardBoundary!.frame.size
        
        let keyboardWidth = keyboardSize.width
        let keyboardHeight = keyboardSize.height * 3/4
        //-----------------------------------------------------------------------------
        
        // Define the number of keys and buttons on each row
        let numNotes: Double = 14 // Notes in two octaves of a major scale
        let numAccidentals: Double = 10 // Accidentals in two octaves of a major scale
        let numButtons: Double = 4 // Octave Up/Down and Adjust Sound +/- buttons
        
        // Add the buttom row of in scale note keys
        for i in 1...Int(numNotes) {
            addKey(position: CGPoint(x: keyboardWidth/numNotes*Double(i)-keyboardWidth/(numNotes*2) - screenWidth/2, y: keyboardHeight*(1/3)-screenHeight/2), height: Int(keyboardHeight*2/3), width: Int(keyboardWidth/numNotes))
        }
        // Add the middle row of accidental note keys
        for i in 1...Int(numAccidentals) {
            addKey(position: CGPoint(x: keyboardWidth/numAccidentals*Double(i)-keyboardWidth/(numAccidentals*2) - screenWidth/2, y: (keyboardHeight*(5/6))-screenHeight/2), height: Int(keyboardHeight*1/3), width: Int(keyboardWidth/numAccidentals))
        }
        
        // Sort the key array by xPosition to determine note order using bubble sort
        // Bubble sort developed using pseudocode credited to: https://www.tutorialspoint.com/data_structures_algorithms/bubble_sort_algorithm.htm
        let n = keyArray.count
        var swapped = true
        for _ in 0...n-1 {
            swapped = false
            for i in 0...n-2 {
                if keyArray[i].position.x > keyArray[i+1].position.x {
                    keyArray.swapAt(i, i+1)
                    swapped = true
                }
            }
            if !swapped {
                break
            }
        }
        
        // Array of the western chromatic scale notes
        let noteNames = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"]
        
        // Loop changes the KeyboardKey text labels to the note names
        var keyArrayIndex = -1
        for key in keyArray {
            keyArrayIndex += 1
            // Reset to the start of the array at each octave
            if keyArrayIndex == 12 {
                keyArrayIndex = 0
            }
            key.label?.text = noteNames[keyArrayIndex]
        }
        
        // Add the top row of buttons to the keyboard
        for i in 1...Int(numButtons) {
            addButton(name: "Button", position: CGPoint(x: keyboardWidth/numButtons*Double(i)-keyboardWidth/(numButtons*2) - screenWidth/2, y: (keyboardHeight*(7/6))-screenHeight/2), height: Int(keyboardHeight*1/3), width: Int(keyboardWidth/numButtons))
        }
        
        // Add the button names in the desired order from left to right
        buttonArray[0].label?.text = "Octave Down"
        buttonArray[1].label?.text = "Octave Up"
        buttonArray[2].label?.text = "Adjust Sound -"
        buttonArray[3].label?.text = "Adjust Sound +"
    }
    
    /// Sets keys at given position to touched and triggers volume envelope. Use for touchesBegan signals only.
    func keyboardTouch(atPoint pos : CGPoint) {
        // Keyboard Touch Behaviour for new touches
        var newTouch = false
        
        // Tells keys if they have been touched
        for node in keyArray {
            if node.contains(pos) {
                node.setTouchState(touchState: true)
                newTouch = true
            }
        }
        
        // Add velocity to the volume circle to trigger volume envelope for a new non-legato touch
        if newTouch {
            boxArray[3].physicsBody?.velocity = CGVector(dx: boxArray[3].physicsBody!.velocity.dx, dy: 1000)
        }
        
    }
    
    /// Sets keys at given positions to touched. Use for touchesMoved signals only.
    func keyboardTouch(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        // Keyboard Touch Behaviour
        for node in keyArray {
            if node.contains(pos) {
                node.setTouchState(touchState: true)
            }
            // Turns off the key if a touch drag exit has occurred
            else if node.contains(prevPos) {
                node.setTouchState(touchState: false)
            }
        }
    }
    
    /// Sets keys at given positions to not touched. Use for touchesEnded or touchesCancelled signals only.
    func keyboardTouchOff(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        // Keyboard Touch Behaviour
        for node in keyArray {
            if node.contains(pos) {
                node.setTouchState(touchState: false)
            }
            else if node.contains(prevPos) {
                node.setTouchState(touchState: false)
            }
        }
    }
    
    /// Sets buttons at given position to touched. Use for touchesBegan signals only.
    func buttonTouch(atPoint pos : CGPoint) {
        for node in buttonArray {
            if node.contains(pos) {
                node.setTouchState(touchState: true)
            }
        }
        
    }
    
    /// Sets buttons at given positions to not touched. Use for touchesEnded or touchesCancelled signals only.
    func buttonTouchOff(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        for button in buttonArray {
            if button.contains(pos) {
                button.setTouchState(touchState: false)
                buttonTouchOffBehaviour(button: button)
            }
            else if button.contains(prevPos) {
                button.setTouchState(touchState: false)
            }
        }
    }
    
    /// Touch drag behaviour for buttons. Turns the button off if the touch leaves the button.
    func buttonTouchDrag(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        // Turns the button off if a touch drag exit has occurred
        for button in buttonArray {
            if !button.contains(pos) && button.contains(prevPos) {
                button.setTouchState(touchState: false)
            }
        }
    }
    
    /// Executes the button's function when a touch up inside occurs.
    private func buttonTouchOffBehaviour(button: KeyboardButton) {
       // Define range of possible keyboard octaves
        let octaveUpperLimit : Int8 = 9
        let octaveLowerLimit : Int8 = 0
        let defaultOctave : Int8 = 4
        
        // Executes the currect behaviour for each labelled button
        switch button.label?.text {
        case "Octave Up":
            // Inscrease the octave if within the allowed range
            if keyboardOctave < octaveUpperLimit && keyboardOctave >= octaveLowerLimit {
                keyboardOctave += 1
            }
            else if keyboardOctave == octaveUpperLimit {
                break
            }
            else {
                keyboardOctave = defaultOctave
            }
        case "Octave Down":
            // Decrease the octave if within the allowed range
            if keyboardOctave <= octaveUpperLimit && keyboardOctave > octaveLowerLimit {
                keyboardOctave += -1
            }
            else if keyboardOctave == octaveLowerLimit {
                break
            }
            else {
                keyboardOctave = defaultOctave
            }
        // Adjust Sound buttons alter the FM modulation frequency
        case "Adjust Sound +":
            audioController.changeFMModMultiplier(change: "Up")
        case "Adjust Sound -":
            audioController.changeFMModMultiplier(change: "Down")
        default: break
        }
    }
    
    /// To be called every time the update() function runs. Updates the keyboard key/button colours. Communicates the frequency
    /// off notes played by the keyboard to the audio controller.
    func updateKeyboard() {
        var noteMIDI : Int8
        var index : Int8 = -1
        
        // Sets the key colours and note of the FM synthesiser
        keyboardIsOn = false
        for node in keyArray {
            index += 1
            if node.getTouchState() {
                node.fillColor = .black
                keyboardIsOn = true
                // Calculate the MIDI note number of the pressed key
                noteMIDI = index + keyboardOctave*12
                // Change the FM synth frequency to match the MIDI note
                audioController.changeOscFreq(frequency: AUValue(noteMIDI).midiNoteToFrequency())
            }
            else {
                node.fillColor = .white
            }
        }
        
        // Sets the button colours
        for button in buttonArray {
            index += 1
            if button.getTouchState() {
                button.fillColor = .yellow
            }
            else {
                button.fillColor = .lightGray
            }
        }
    }
    
    
    // -----------------------------
    // -------------------- Physics Objects ---------------------------
    
    /// Construct the physics sandbox
    func addPhysicsScene() {
        
        // Define the sandbox size and create the background
        physicsBoundary = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height * CGFloat(physicsBoundaryScale)))
        physicsBoundary?.position = CGPoint(x: 0, y: frame.height * CGFloat(1-physicsBoundaryScale)/2)
        physicsBoundary?.fillColor = .black
        // Add the background to the scene
        addChild(physicsBoundary!)
        
        print(frame.width, frame.height)
        
        // Set up edge boundaries and remove any gravity
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundary!.frame)
        physicsBody?.friction = 0.0
        physicsWorld.gravity = CGVector(dx: 0, dy: -3)
         
        // Run functions to set up all other objects
        determineLayout()
        addBoxes()
        addAnchors()
        addPins()
    }
    
    /// Controls the positions of all physics objects and SKNodes within the physics sandbox
    func determineLayout() {
        // Attributes of the physics objects for layout
        numBoxes = 6
        boxColourArray = [.red, .orange, .yellow, .green, .blue, .purple]
        circleArray = [false, true, false, true, false, false]
        boxRotatableArray = [true, false, false, false, false, false]
        massArray = [1, 4, 9, 16, 25, 36]
        
        
        // BOX POSITIONS
        // red box
        let redBoxPosition = CGPoint(x: (frame.width)*(1/10), y: (physicsBoundary?.position.y)!)
        boxPositionArray.append(redBoxPosition)
    
        // orange box
        let orangeBoxPosition = CGPoint(x: -frame.width * 1/5, y: (physicsBoundary?.position.y)!)
        boxPositionArray.append(orangeBoxPosition)
        
        // yellow box
        boxPositionArray.append(CGPoint(x: 150, y: 200))
        
        // green box
        let greenBoxPosition = CGPoint(x: -frame.width * 2/5, y: (physicsBoundary?.position.y)!)
        boxPositionArray.append(greenBoxPosition)
        
        // blue box
        boxPositionArray.append(CGPoint(x: 200, y: 0))
        
        // purple box
        boxPositionArray.append(CGPoint(x: 300, y: 0))
        
        // Boundaries (the yellow walls)
        let dividerWidth : CGFloat = 30
        let boxDividerAXPositionScaler : CGFloat = 3/10
        
        let boxDividerAPosition = CGPoint(x: -frame.width * boxDividerAXPositionScaler, y: physicsBoundary!.position.y)
        let boxDividerASize = CGSize(width: dividerWidth, height: frame.height * CGFloat(physicsBoundaryScale))
        
        // Left hand yellow wall
        boxDividerA = SKShapeNode(rectOf: boxDividerASize)
        
        boxDividerA.position = boxDividerAPosition
        boxDividerA.fillColor = .yellow
        boxDividerA.physicsBody = SKPhysicsBody(rectangleOf: boxDividerASize)
        boxDividerA.physicsBody?.isDynamic = false
        
        addChild(boxDividerA)
        
        let boxDividerBXPositionScaler : CGFloat = 1/10
        
        let boxDividerBPosition = CGPoint(x: -frame.width * boxDividerBXPositionScaler, y: physicsBoundary!.position.y)
        let boxDividerBSize = CGSize(width: dividerWidth, height: frame.height * CGFloat(physicsBoundaryScale))
        
        // Right hand yellow wall
        boxDividerB = SKShapeNode(rectOf: boxDividerBSize)
        
        boxDividerB.position = boxDividerBPosition
        boxDividerB.fillColor = .yellow
        boxDividerB.physicsBody = SKPhysicsBody(rectangleOf: boxDividerBSize)
        boxDividerB.physicsBody?.isDynamic = false
        
        addChild(boxDividerB)
    }
    
    /// Adds physics boxes (squares and circles) to the physics sandbox.
    func addBoxes() {
        
        for i in 0...numBoxes-1 {
            // Add the box as a circle or a square using the circleArray for reference
            if circleArray[i] {
                boxArray.append(PhysicsBox(circleOfRadius: boxSize.width * 0.5))
                boxArray[i].physicsBody = SKPhysicsBody(circleOfRadius: boxSize.width * 0.5)
            }
            else {
                boxArray.append(PhysicsBox(rectOf: boxSize))
                boxArray[i].physicsBody = SKPhysicsBody(rectangleOf: boxSize)
            }
            
            // Set the attributes of the created box
            boxArray[i].fillColor = boxColourArray[i]
            boxArray[i].position = boxPositionArray[i]
            boxArray[i].rotatable = boxRotatableArray[i]
            
            // If the box is a spinning box, set it to rotate at start
            if boxArray[i].rotatable {
                boxArray[i].physicsBody?.angularVelocity = -1
            }
            
            // Set the physics properties of the box
            boxArray[i].physicsBody?.isDynamic = true
            boxArray[i].physicsBody?.restitution = 0.9
            boxArray[i].physicsBody?.linearDamping = 0.1
            boxArray[i].physicsBody?.angularDamping = 0.1
            boxArray[i].physicsBody?.friction = 0.1
            
            boxArray[i].physicsBody?.mass = massArray[i]
            
            // Add the box to the scene
            addChild(boxArray[i])
        }
        // Make the box controlling vibrato slightly larger
        boxArray[0].yScale = 1.5
        boxArray[0].xScale = 1.5
    }
    
    /// Adds a physics anchor point to the centre of any rotating boxes
    func addAnchors() {
        let rotatableAnchorSize = CGSize(width: 50, height: 50)
        
        // Set up achors for rotating physics objects
        for box in boxArray {
            if box.rotatable {
                setUpAnchor(position: box.position, size: rotatableAnchorSize)
            }
        }
    }
    
    /// Sets up the properties of the central anchor for spinning boxes, and appends them to the anchorArray.
    func setUpAnchor(position anchorPosition : CGPoint, size anchorSize : CGSize) {
        let anchor = SKShapeNode(rectOf: anchorSize)
        
        anchor.position = anchorPosition
        anchor.fillColor = .white
        anchor.strokeColor = .black
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchorSize)
        anchor.physicsBody?.isDynamic = false
        
        anchorArray.append(anchor)
        addChild(anchor)
    }
    
    // Implementation of Physics Joints used the following video presentation for reference:
    // 'Making a Joint with SpriteKit (/dev/world/2014)'
    // https://youtube.com/watch?v=2OztjXKQCMQ&feature=shares
    
    /// Sets up physics pin joints for rotating PhysicsBoxes
    func addPins() {
        for i in 0...(numBoxes-1) {
            if boxArray[i].rotatable {
                let pin = SKPhysicsJointPin.joint(withBodyA: boxArray[i].physicsBody!, bodyB: anchorArray[i].physicsBody!, anchor: boxArray[i].position)
                
                setUpPin(pin: pin)
                
                physicsWorld.add(pin)
            }
        }
    }
    
    /// Sets the physics properties of a pin joint
    func setUpPin(pin: SKPhysicsJointPin) {
        pin.frictionTorque = 0
    }
    
    // ---------------------- TOUCH BEHAVIOUR FUNCTIONS ----------------------------
    
    /// Defintes what happens when a touch down occurs within a PhysicsBox. Use for touchesBegan signals only.
    func boxTouch(atPoint pos : CGPoint) {
        // If a box has been touched change the colour
        for box in boxArray {
            if box.frame.contains(pos) && !anchorArray[0].contains(pos) {
                box.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                box.touchState = true
                box.physicsBody?.isDynamic = false
            }
        }
    }
    
    /// Defintes what happens when a touch drag occurs within a PhysicsBox. Use for touchesMoved signals only.
    func boxDrag(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        // Work out how far a user's finger has moved across the screen
        let location = pos
        let prevLocation = prevPos
        
        for box in boxArray {
            // Move the red box according to the touch drag
            if box.touchState {
                if !box.rotatable {
                    if box.frame.contains(prevPos) {
                        box.position.x += location.x - prevLocation.x
                        box.position.y += location.y - prevLocation.y
                        box.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                        
                        if !physicsBoundary!.contains(box.position) {
                            box.position.x += prevLocation.x - location.x
                            box.position.y += prevLocation.y - location.y
                        }
                    }
                }
            }
        }
    }
    
    /// Defintes what happens when a touch drag occurs within the central anchor of a rotatable PhysicsBox.
    /// Use for touchesMoved signals only.
    func anchorDrag(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        // Work out how far a user's finger has moved across the screen
        let location = pos
        let prevLocation = prevPos
        
        for anchor in anchorArray {
            // Move the red box according to the touch drag
            if anchor.frame.contains(prevPos) {
                anchor.position.x += location.x - prevLocation.x
                //box.position.y += location.y - prevLocation.y
                anchor.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                if anchor.position.x < 20 {
                    anchor.position.x = 20
                }
                else if anchor.position.x > 400 {
                    anchor.position.x = 400
                }
            }
        }
    }
    
    /// Defintes what happens to a rotatable PhysicsBox when a touch drag occurs within it.
    func boxRotate(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        let location = pos
        let prevLocation = prevPos
        
        for box in boxArray {
            if box.rotatable {
                // If a touch drag occurs on the rotating box it will move to match the drag
                if box.contains(location) && !anchorArray[0].contains(location) {
                    box.zRotation += touchDragAngularVelocity(toPoint: location, fromPoint: prevLocation, objectLocation: box.position)
                }
                // If a touch drag exit occurs on the rotating box it will spin by itself
                else if box.contains(prevLocation) && !anchorArray[0].contains(location) {
                    box.physicsBody?.isDynamic = true
                    box.physicsBody!.angularVelocity = touchDragAngularVelocity(toPoint: location, fromPoint: prevLocation, objectLocation: box.position) * frameTimeReciprocal
                    box.touchState = false
                }
            }
        }
    }
    
    /// Calculates the angle change promoted for a rotatable PhysicsBox when the user drags on it. Returns radians.
    func touchDragAngularVelocity(toPoint pos : CGPoint, fromPoint prevPos : CGPoint, objectLocation objPos : CGPoint)->CGFloat {
        
        // Works out the angle change promoted by the touch movement
        let phi = atan2((prevPos.x-objPos.x), (prevPos.y-objPos.y)) // previous angle
        let prevPhi = atan2((pos.x-objPos.x), (pos.y-objPos.y)) // current angle
        let theta = phi-prevPhi // angle change
        
        return theta
    }
    
    /// Gives the box a linear velocity when dragged and let go.
    func boxThrow(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        
        // Calculate the release velocity of the user's touch
        let location = pos
        let prevLocation = prevPos
        let velocity = CGVector(dx: Double(location.x - prevLocation.x)/(frameTime), dy: Double(location.y - prevLocation.y)/(frameTime))
        
        var i : Int = -1
        for box in boxArray {
            i += 1
            
            // Sets throw velocity
            if box.frame.contains(location) {
                box.physicsBody?.isDynamic = true
                box.physicsBody?.velocity = CGVector(dx: velocity.dx, dy: velocity.dy)
                box.touchState = false
            }
        }
    }
    
    /// Calculates the angular velocity with which a rotatable PhysicsBox should spin when dragged and let go.
    func boxSpin(fromPoint prevPos : CGPoint, toPoint pos : CGPoint) {
        let frameTimeReciprocal: Double = 60.0 // because the app runs at 60Hz
        
        let location = pos
        let prevLocation = prevPos
        
        var i : Int = -1
        for box in boxArray {
            if box.rotatable {
                i += 1
                let angularVelocity = touchDragAngularVelocity(toPoint: location, fromPoint: prevLocation, objectLocation: box.position)
                // Sets release angular velocity if the drag and release occurred on the box
                if box.frame.contains(location) && !anchorArray[0].contains(location) {
                    box.physicsBody?.isDynamic = true
                    box.physicsBody!.angularVelocity = angularVelocity * frameTimeReciprocal
                    box.touchState = false
                }
            }
        }
    }
    
    //----------------- User Interaction Functions -------------
    
    /// Sends touch down positions to the keyboard and physics sandbox
    func touchDown(atPoint pos : CGPoint) {
        // Keyboard
        keyboardTouch(atPoint: pos)
        buttonTouch(atPoint: pos)
        // Physics Sandbox
        boxTouch(atPoint : pos)
    }
    
    /// Sends touch drag positions to the keyboard and physics sandbox
    func touchMoved(fromPoint prevPos: CGPoint, toPoint pos : CGPoint) {
        // Keyboard
        keyboardTouch(fromPoint: prevPos, toPoint: pos)
        buttonTouchDrag(fromPoint: prevPos, toPoint: pos)
        
        // Physics Sandbox
        boxDrag(fromPoint: prevPos, toPoint: pos)
        anchorDrag(fromPoint: prevPos, toPoint: pos)
        boxRotate(fromPoint: prevPos, toPoint: pos)
    }
    
    /// Sends touch ended or cancelled signals to the keyboard and physics sandbox
    func touchUp(fromPoint prevPos: CGPoint, toPoint pos : CGPoint) {
        // Keyboard
        keyboardTouchOff(fromPoint: prevPos, toPoint: pos)
        buttonTouchOff(fromPoint: prevPos, toPoint: pos)
        
        // Physics Sandbox
        boxThrow(fromPoint: prevPos, toPoint: pos)
        boxSpin(fromPoint: prevPos, toPoint: pos)
    }
    
    // ------------------------------------------------------------------------------
    // ----------------------- Overridden Functions ---------------------------------
    // ------------------------------------------------------------------------------
    
    // Collect touches and send to behavour functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(fromPoint: t.previousLocation(in: self), toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(fromPoint: t.previousLocation(in: self), toPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(fromPoint: t.previousLocation(in: self), toPoint: t.location(in: self)) }
    }
    
    // Set all changes that need to occur each time a new frame is drawn
    override func update(_ currentTime: TimeInterval) {
        var volumeParameter : Float!
        var fmAmplitudeParameter : Float!
        var vibratoParameter: Float!
        let fmAmpParamScaler : Float = 2000
        
        // Apply keyboard and audio changes
        updateKeyboard()
        audioController.updatePitchMod(boxRotation: boxArray[0].zRotation)
        audioController.playState(isKeyboardTouched: keyboardIsOn)
        
        // Updates the volume based on the green ball's vertical position
        // Normalise PhysicsBox vertical position to a value between 0 and 1 for updateAmpEnvelope function input
        volumeParameter = (Float(boxArray[3].position.y) + Float(frame.height * 3/10)) / Float(physicsBoundary!.frame.height)
        
        // Set the volume ball to bounce if the keyboard is being played or resist bouncing otherwise
        if keyboardIsOn {
            boxArray[3].physicsBody!.restitution = 0.8
            audioController.updateAmpEnvelope(volume: volumeParameter)
        }
        else {
            boxArray[3].physicsBody!.restitution = 0
        }
        
        // Updates the brightness (FM amplitude) based on the orange ball's vertical position
        fmAmplitudeParameter = ((Float(boxArray[1].position.y) + Float(frame.height * 3/10)) / Float(physicsBoundary!.frame.height)) * fmAmpParamScaler
        audioController.updateFMAmplitude(fmAmplitude: fmAmplitudeParameter)
        
        // Sets the amount of vibrato applied based upon the vibrato box's horizontal position
        vibratoParameter = Float(anchorArray[0].position.x/400)
        audioController.updatePitchModDepth(anchorPosition: vibratoParameter)
    }
}

