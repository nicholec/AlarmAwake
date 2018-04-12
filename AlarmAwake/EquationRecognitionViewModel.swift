//
//  EquationRecognitionViewModel.swift
//  AlarmAwake
//
//  Created by Nichole on 4/9/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import AVFoundation
import Speech
import SwiftTryCatch
import ReactiveSwift

class EquationRecognizerViewModel: NSObject, SFSpeechRecognitionTaskDelegate {
    var player: AVAudioPlayer?
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    var request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var equation: MutableProperty<String> = MutableProperty("")
    var processedEquation: String = ""
    var spokenEquation: String = ""
    var numericalEquation: String = ""
    let synth = AVSpeechSynthesizer()
    let answer = arc4random_uniform(99)
    
    init(player: AVAudioPlayer?) {
        self.player = player
    }
}

// Recording Functionality
extension EquationRecognizerViewModel {
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            switch authStatus {
            case .authorized:
                // save authorization
                break
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
    
    public func startRecording(completion: () -> Void) {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 1)
        
        node.installTap(onBus: 1, bufferSize: 1024, format: recordingFormat) { [unowned self] buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            recognitionTask = speechRecognizer?.recognitionTask(with: request, delegate: self)
            completion()
        } catch (let error) {
            print("There was a problem starting the recording: \(error.localizedDescription)")
        }
    }
    
    public func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 1)
        request.endAudio()
        recognitionTask?.cancel()
        request = SFSpeechAudioBufferRecognitionRequest()
    }
}

// Equation Processing
extension EquationRecognizerViewModel {
    internal func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        equation.value = transcription.formattedString.replace(target: " one", withString: "1")
        processForFormattedEquation()
        
    }
    
    private func processForFormattedEquation() {
        self.processedEquation = equation.value.replace(target: "×", withString: "*")
        self.spokenEquation = self.processedEquation.replace(target: "-", withString: " minus ")
        self.processedEquation = self.processedEquation.replace(target: "÷", withString: "/")
        print(self.processedEquation)
    }
    
    public func processEquation(completion: @escaping ((_ correct: Bool) -> Void)) {
        processForFormattedEquation()
        var utterance = AVSpeechUtterance(string: "")
        utterance.rate = 0.5
        if equation.value.isEmpty {
            utterance = AVSpeechUtterance(string: "Make sure you say an equation")
            self.synth.speak(utterance)
        } else {
            SwiftTryCatch.try({
                let expr = NSExpression(format: self.processedEquation)
                if let result = expr.expressionValue(with: [], context: nil) as? Double {
                    if (self.answer <= 18 && self.equation.value.count - String(self.answer).count < 1) || self.answer > 18 &&  self.equation.value.count - String(self.answer).count < 2 {
                        utterance = AVSpeechUtterance(string: "Try a longer equation")
                        self.synth.speak(utterance)
                        completion(false)
                    } else {
                        print(result)
                        let response = "\(self.spokenEquation) equals \(Int(result)). \(Double(self.answer) == result ? "That's right!" : "Try again.")"
                        utterance = AVSpeechUtterance(string: response)
                        self.synth.speak(utterance)
                        completion(Double(self.answer) == result)
                    }
                } else {
                    utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.spokenEquation)")
                    self.synth.speak(utterance)
                    completion(false)
                }
            }, catch: { (error) in
                utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.spokenEquation)")
                self.synth.speak(utterance)
                completion(false)
            }, finallyBlock: {
                // close resources
            })
        }
    }
}
