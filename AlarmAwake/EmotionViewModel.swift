//
//  EmotionViewModel.swift
//  AlarmAwake
//
//  Created by Nichole on 4/23/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import Affdex
import AVKit
import Speech
import ReactiveSwift

public enum EmoExpr: Int {
    case BrowRaise = 1
    case LipSuck = 2
    case Smile = 3
    case Kiss = 4
    case BrowFurrow = 5
    case JawDrop = 6
    
    func str() -> String {
        switch self {
        case .BrowRaise:
            return "Brow Raise"
        case .LipSuck:
            return "Lip Suck"
        case .Smile:
            return "Smile"
        case .Kiss:
            return "Pucker"
        case .BrowFurrow:
            return "Brow Furrow"
        case .JawDrop:
            return "JawDrop"
        }
    }
}

struct EmoExprScore {
    let type: EmoExpr
    let score: CGFloat
}

protocol AffdexDisplayDelegate {
    func onImageReady(image: UIImage)
    func dominantEmotionColoring(dominantEmoExpr: EmoExprScore)
    func onFaceDetected(found: Bool)
}

class EmotionViewModel: AFDXDetectorDelegate {
    private var detector: AFDXDetector? = nil
    private var player: AVAudioPlayer?
    let synth = AVSpeechSynthesizer()
    private var affdexDisplayDelegate: AffdexDisplayDelegate
    
    var exprPattern: [EmoExpr] = [EmoExpr]()
    var lastPatternAttempt: [EmoExpr] = [EmoExpr]()
    var currAttempt: Int = 0
    var fullPatternAttempts: Int = 0
    var replayAfter = Int.random(lower: 3, upper: 6)
    private var usersSelectedPattern: [EmoExpr] = [EmoExpr]()
    let difficulty: ModeDifficulty //update this to not be optional
    let patternLength: Int
    let numberToSolveFor: Int
    var numTimesCorrect: MutableProperty<Int> = MutableProperty(0)
    var patternsSolvedFor: [[EmoExpr]] = [[EmoExpr]]()
    
    init(player: AVAudioPlayer?, delegate: AffdexDisplayDelegate, difficultySetting: Int, numCorrectNeeded: Int) {
        self.player = player
        self.affdexDisplayDelegate = delegate
        self.difficulty = ModeDifficulty(rawValue: difficultySetting)!
        self.patternLength = difficulty == .Easy ? 4 : 5
        self.numberToSolveFor = numCorrectNeeded
        detector = AFDXDetector(delegate:self, using:AFDX_CAMERA_FRONT, maximumFaces:1)
        detector?.setDetectEmojis(true)
        detector?.setDetectAllEmotions(true)
        detector?.setDetectAllExpressions(true)
        exprPattern = generateExprExpression()
    }
    
    private func generateExprExpression() -> [EmoExpr] {
        var exprList: [EmoExpr] = [EmoExpr]()
        
        while exprList.count < patternLength {
            let randExpr = EmoExpr(rawValue: Int.random(lower: 1, upper: 6))!
            let count = exprList.filter{$0 == randExpr}.count
            if count < 2 && exprList.last != randExpr {
                exprList.append(randExpr)
            }
        }
        
        return exprList
    }
    
    func generateNextPattern() {
        patternsSolvedFor.append(exprPattern)
        
        var exprList = generateExprExpression()
        while patternsSolvedFor.contains(exprList) {
            exprList = generateExprExpression()
        }
        
        exprPattern = exprList
    }
    
    func emoExprAdded(selectedExprEmo: EmoExpr, completion: (_ fullPattern: Bool, _ correct: Bool, _ dimiss: Bool) -> Void) {
        self.usersSelectedPattern.append(selectedExprEmo)
        currAttempt += 1
        
        let fullPattern = usersSelectedPattern.count == patternLength
        let correct = usersSelectedPattern == exprPattern
        
        if fullPattern {
            fullPatternAttempts += 1
            print("SOLVED? \(correct)")
            lastPatternAttempt = usersSelectedPattern
            currAttempt = 0
            usersSelectedPattern = [EmoExpr]()
            if correct {
                self.numTimesCorrect.value += 1
                fullPatternAttempts = 0
            }
        }
        
        let done = numTimesCorrect.value == numberToSolveFor
        
        if done {
            self.player?.stop()
        }
        
        completion(fullPattern, correct, done)
    }
    
    func replayedPattern() {
        fullPatternAttempts = 0
        replayAfter = Int.random(lower: 3, upper: 5)
    }
    
    func CPUResponse(_ correct: Bool) {
        let utterance = AVSpeechUtterance(string: correct ? "That's right!!" : "Wrong pattern.")
        synth.speak(utterance)
    }
}

// Affdex Detection Methods
extension EmotionViewModel {
    func detector(_ detector: AFDXDetector!, didStartDetecting face: AFDXFace!) {
        // handle a new face
        print("FACE BOUNDS: \(face.faceBounds)")
        self.affdexDisplayDelegate.onFaceDetected(found: true)
    }
    
    func detector(_ detector: AFDXDetector!, didStopDetecting face: AFDXFace!) {
        // handle no longer detecting face
        self.affdexDisplayDelegate.onFaceDetected(found: false)
    }
    
    func startDetectingForFaces() {
        self.detector?.start()
    }
    
    func stopDetectingFaces() {
        self.detector?.stop()
    }
    
    func detector(_ detector: AFDXDetector!, hasResults faces: NSMutableDictionary!, for image: UIImage!, atTime time: TimeInterval) {
        self.affdexDisplayDelegate.onImageReady(image: image)
        
        guard let faces = faces as? [Int: AFDXFace] else {
            return
        }
        
        for (_, face) in faces {
            let emojis : AFDXEmoji = face.emojis
            let expressions : AFDXExpressions = face.expressions
            var exprs: [EmoExprScore] = [EmoExprScore]()
            
            exprs.append(EmoExprScore(type: .BrowRaise, score: expressions.browRaise))
            exprs.append(EmoExprScore(type: .BrowFurrow, score: expressions.browFurrow))
            exprs.append(EmoExprScore(type: .LipSuck, score: expressions.lipSuck))
            exprs.append(EmoExprScore(type: .Smile, score: expressions.smile))
            exprs.append(EmoExprScore(type: .JawDrop, score: expressions.jawDrop))
            exprs.append(EmoExprScore(type: .Kiss, score: expressions.lipPucker))
            
            print(exprs)
            
            let dominantEmoExpr = exprs.max{ $0.score < $1.score }
            
            self.affdexDisplayDelegate.dominantEmotionColoring(dominantEmoExpr: dominantEmoExpr!)
        }
    }
}
