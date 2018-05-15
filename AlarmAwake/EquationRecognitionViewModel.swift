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

enum ModeDifficulty: Int {
    case Easy = 0
    case Medium = 1
    case Hard = 2
}

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
    var answer: MutableProperty<Int>
    let equationDifficulty: ModeDifficulty
    let correctNeeded: Int
    var numTimesCorrect: MutableProperty<Int> = MutableProperty(0)
    var numbersSolvedFor: Set<Int> = Set()
    
    init(player: AVAudioPlayer?, difficultySetting: Int, numCorrectNeeded: Int) {
        self.player = player
        self.equationDifficulty = ModeDifficulty(rawValue: difficultySetting)!
        self.correctNeeded = numCorrectNeeded
        let lowerBound = (difficultySetting + 1) * 5
        let upperBound = (difficultySetting + 1) * 100
        self.answer = MutableProperty(Int.random(lower: lowerBound, upper: upperBound))
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
        
        self.equation.value = ""
        
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
    
    public func stopRecording(completion: () -> Void) {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 1)
        request.endAudio()
        recognitionTask?.cancel()
        request = SFSpeechAudioBufferRecognitionRequest()
        completion()
    }
    
    public func askForEquation() {
        let utterance = AVSpeechUtterance(string: "Give me an equation that evaluates to \(String(answer.value))")
        utterance.rate = 0.5
        self.synth.speak(utterance)
    }
}

// Equation Generating + Processing
extension EquationRecognizerViewModel {
    internal func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        equation.value = transcription.formattedString
//        processForFormattedEquation()
    }
    
    private func processForFormattedEquation() {
        self.equation.value = self.equation.value.replace(target: " one", withString: "1").replace(target: " minus", withString: "-").replace(target: "One", withString: "1")
        self.processedEquation = equation.value.replace(target: "×", withString: "*")
        self.processedEquation = self.processedEquation.replace(target: "÷", withString: "/")
        
        self.spokenEquation = self.processedEquation.replace(target: "-", withString: " minus ")
        self.spokenEquation = self.spokenEquation.replace(target: "*", withString: " times ")
        self.spokenEquation = self.spokenEquation.replace(target: "/", withString: " divided by ")
        
        print(self.processedEquation)
    }
    
    private func minLengthForDifficultySetting() -> Int {
        switch equationDifficulty {
        case .Easy:
            return 1
        case .Medium:
            return 3
        case .Hard:
            return 5
        }
    }
    
    private func generateNextNumber() {
        numbersSolvedFor.insert(self.answer.value)
        var new_num = Int.random(lower: minLengthForDifficultySetting()*5, upper: minLengthForDifficultySetting()*100)
        while new_num == self.answer.value || numbersSolvedFor.contains(new_num) {
            new_num = Int.random(lower: minLengthForDifficultySetting()*5, upper: minLengthForDifficultySetting()*100)
        }
        self.answer.value = new_num
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.equation.value = ""
        }
        askForEquation()
    }
    
    private func numberOfOperatorsNoOnes() -> Int {
        let operatorsOnlyRegex = "[^-+/*]"
        let removeOnlyOnesRegex = "[-+/*][0-1](?=([-+/*])|$)"
        let removeLeadingOnesRegex = "^1([-+/*]|$)"
        
        let removedLeadingOnesEquation = self.processedEquation.removingRegexMatches(pattern: removeLeadingOnesRegex)
        let removingOnesEquation = removedLeadingOnesEquation?.removingRegexMatches(pattern: removeOnlyOnesRegex)
        let operatorsOnlyEquation = removingOnesEquation?.removingRegexMatches(pattern: operatorsOnlyRegex)
        
        return operatorsOnlyEquation?.count ?? 0
    }
    
    private func totalOperators() -> Int {
        let operatorsOnlyRegex = "[^-+/*]"
        let onlyOperators = self.processedEquation.removingRegexMatches(pattern: operatorsOnlyRegex)
        return onlyOperators?.count ?? 0
    }
    
    public func processEquation(completion: @escaping ((_ correct: Bool, _ dismiss: Bool) -> Void)) {
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
                    let operatorsCount = self.numberOfOperatorsNoOnes()
                    let allOperatorsCount = self.totalOperators()
                    if (operatorsCount < self.minLengthForDifficultySetting()) {
                        utterance = allOperatorsCount < self.minLengthForDifficultySetting() ? AVSpeechUtterance(string: "Try a longer equation") : AVSpeechUtterance(string: "Remember, 1's and 0's terms don't count")
                        self.synth.speak(utterance)
                        completion(false, false)
                    } else {
                        print(result)
                        let response = "\(self.spokenEquation) equals \(Int(result)). \(Double(self.answer.value) == result ? "That's right!" : "Try again.")"
                        utterance = AVSpeechUtterance(string: response)
                        self.synth.speak(utterance)
                        if Double(self.answer.value) == result {
                            self.numTimesCorrect.value += 1
                            if self.numTimesCorrect.value == self.correctNeeded {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    completion(true, true)
                                }
                            } else {
                                self.generateNextNumber()
                                completion(true, false)
                            }
                        } else {
                            completion(false, false)
                        }
                        
                    }
                } else {
                    utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.spokenEquation)")
                    self.synth.speak(utterance)
                    completion(false, false)
                }
            }, catch: { (error) in
                utterance = AVSpeechUtterance(string: "Unable to process your equation: \(self.spokenEquation)")
                self.synth.speak(utterance)
                completion(false, false)
            }, finallyBlock: {
                // close resources
            })
        }
    }
}

extension String {
    func removingRegexMatches(pattern: String, replaceWith: String = "") -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return nil
        }
    }
}

public extension Int {
    public static func random(lower: Int , upper: Int) -> Int {
        return lower + Int(arc4random_uniform(UInt32(1 + upper - lower)))
    }
}
