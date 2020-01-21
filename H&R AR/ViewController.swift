//
//  ViewController.swift
//  H&R AR
//
//  Created by Bhanuka Gamage on 1/18/20.
//  Copyright © 2020 Bhanuka Gamage. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Speech

class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var userInput: UILabel!
    @IBOutlet weak var chatBotReply: UILabel!
    
    
    @IBOutlet weak var speechButton: UIButton!
    @IBAction func pressedSenderButton(_ sender: UIButton) {
        
        if audioEngine.isRunning {
            self.recognitionRequest?.endAudio()
            self.audioEngine.stop()
            self.speechButton.isEnabled = false
            self.speechButton.tintColor = UIColor.systemBlue
        } else {
            self.startRecording()
            self.speechButton.tintColor = UIColor.red
            self.speechText.text = "Say something, I'm listening!"
        }
    
    }
    
    
    @IBOutlet weak var speechText: UILabel!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var location : SCNVector3 = SCNVector3(
        x: 0,
        y: 0,
        z: 0
    )
    
    var avatarAdded:Bool = false
    
    var chatBot: ChatBot = ChatBot()
    
    var currentTextNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.autoenablesDefaultLighting = true
        
        self.hideKeyboardWhenTappedAround()
        
        self.textField.delegate = self
        
        self.setupSpeech()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            if avatarAdded == false {
                avatarAdded = true
                
                let touchLocation = touch.location(in: sceneView)
                                    
                let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
                
                if let hitResult = results.first {
                    
                    location = SCNVector3(
                        x: hitResult.worldTransform.columns.3.x,
                        y: hitResult.worldTransform.columns.3.y + 0.1,
                        z: hitResult.worldTransform.columns.3.z
                    )

                    // Create a new scene
                    let avatarScene = SCNScene(named: "art.scnassets/avatar.scn")!
                    
                    if let avatarNode = avatarScene.rootNode.childNode(withName: "Avatar", recursively: false) {

                        avatarNode.position = SCNVector3(
                            x: hitResult.worldTransform.columns.3.x,
                            y: hitResult.worldTransform.columns.3.y - 0.07,
                            z: hitResult.worldTransform.columns.3.z
                        )
                        
                        let action = SCNAction.scale(by: 0.1, duration: 1.0)
                        
                        avatarNode.runAction(action)

                        sceneView.scene.rootNode.addChildNode(avatarNode)

                    }
                    
                    sceneView.autoenablesDefaultLighting = true
                    
                }
            }
        }
    }
    
    func updateLabel(newText:String){

        let text = SCNText(string: newText, extrusionDepth: 2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        text.materials = [material]
        
        let planeNode = SCNNode()
        
//                    plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
        
        planeNode.position = location
        
        planeNode.scale = SCNVector3(
            x: 0.0005,
            y: 0.0005,
            z: 0.0005
        )
        
        planeNode.geometry = text
        
        currentTextNode?.removeFromParentNode()
        currentTextNode = planeNode
        sceneView.scene.rootNode.addChildNode(planeNode)
    }
    
    func textFieldShouldReturn(_ tF: UITextField) -> Bool {
        if textField == tF {
            textField.resignFirstResponder()
            let inputText = textField.text ?? ""
            talk(inputText)
            return true
        }
        return false
    }
    
    func talk(_ inputText: String) {
        chatBot.talk(input: inputText, completed: { line in
            print("ChatBot:", line)
            self.updateLabel(newText: line)
            self.chatBot.textToSpeech(text: line)
            self.textField.text = ""
        })
    }
    
    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()

    func setupSpeech() {
        self.speechButton.isEnabled = false
        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
                case .authorized:
                    isButtonEnabled = true

                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")

                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")

                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
        
                @unknown default:
                    fatalError()
            }

            OperationQueue.main.addOperation() {
                self.speechButton.isEnabled = isButtonEnabled
            }
        }
    }

    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
            print(error)
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {
                self.speechText.text = "You said: \(result?.bestTranscription.formattedString ?? "Nothing")"
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {
                self.talk(result?.bestTranscription.formattedString ?? "")

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.speechButton.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

    }

}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.speechButton.isEnabled = true
        } else {
            self.speechButton.isEnabled = false
        }
    }
}
