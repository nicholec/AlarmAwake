//
//  EquationRecognizerViewController.swift
//  AlarmAwake
//
//  Created by Nichole Clarke on 4/5/18.
//  Copyright © 2018 mac. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import SwiftTryCatch

class EquationRecognizerViewController: UIViewController, SFSpeechRecognitionTaskDelegate {
    
    fileprivate var player: AVPlayer?
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    var request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var equation: String = ""
    let synth = AVSpeechSynthesizer()
    let answer = arc4random_uniform(109)
    
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var equationLabel: UILabel!
    
    //IBOutlet Information
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorization()
        self.numberLabel.text = String(answer)
        self.equationLabel.text = ""
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.cancelsTouchesInView = false
        recordingButton.addGestureRecognizer(longPressGesture)
    }
    
    @IBAction func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch  gestureRecognizer.state {
        case .began:
            print("BEGAN")
            startRecording()
        case .ended:
            print("exited")
            stopRecording()
            processEquation()
        default:
            break
        }
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            switch authStatus {
            case .authorized:
                break
//                self.startRecording()
            case .denied:
                print("Denied")
            // show an alert instead
            case .restricted:
                print("Not available")
            // show an alert instead
            case .notDetermined:
                print("lol hm")
            }
        }
    }
    
    private func startRecording() {
        DispatchQueue.main.async {
            self.equation = ""
            self.equationLabel.text = "Your equation:"
        }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [unowned self] buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            recognitionTask = speechRecognizer?.recognitionTask(with: request, delegate: self)
        } catch (let error) {
            print("There was a problem starting the recording: \(error.localizedDescription)")
        }
    }
    
    internal func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        equation = transcription.formattedString.replace(target: " one", withString: "1")
        self.equationLabel.text = "Your equation: \(equation)"
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        recognitionTask?.cancel()
        request = SFSpeechAudioBufferRecognitionRequest()
    }
    
    private func processEquation() {
        var utterance = AVSpeechUtterance(string: "")
        utterance.rate = 0.5
        if equation.isEmpty {
            utterance = AVSpeechUtterance(string: "Make sure you say an equation")
            self.synth.speak(utterance)
        } else {
            SwiftTryCatch.try({
                let expr = NSExpression(format: self.equation)
                if let result = expr.expressionValue(with: [], context: nil) as? Double {
                    print(result)
                    let response = "\(self.equation) equals \(Int(result)). \(Double(self.answer) == result ? "That's right!" : "Try again.")"
                    utterance = AVSpeechUtterance(string: response)
                    self.synth.speak(utterance)
                } else {
                    utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.equation)")
                    self.synth.speak(utterance)
                }
            }, catch: { (error) in
                utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.equation)")
                self.synth.speak(utterance)
            }, finallyBlock: {
                // close resources
            })
        }
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}


