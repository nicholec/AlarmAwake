//
//  MainAlarmViewController.swift
//  AlarmAwake
//
//  Created by Nichole on 4/7/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox
import AVFoundation
import PopupDialog

class MainAlarmViewController: UIViewController {
    
    var timer = Timer()
    var time = 3
    var timerIsRunning = false
    var player: AVAudioPlayer?
    @IBOutlet weak var difficultySegControl: UISegmentedControl!
    @IBOutlet weak var modalitySegControl: UISegmentedControl!
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var startAlarmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addDoneButtonOnKeyboard()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startEquationRecognizer" {
            if let viewController = segue.destination as? EquationRecognizerViewController {
                let viewModel = EquationRecognizerViewModel(player: player, difficultySetting: difficultySegControl.selectedSegmentIndex, numCorrectNeeded: Int((self.numberTextField.text?.isEmpty)! ? "1" : self.numberTextField.text!)!, alertDelegate: viewController)
                viewController.viewModel = viewModel
            }
        } else if segue.identifier == "startEmotionGame" {
            if let viewController = segue.destination as? EmotionViewController {
                let viewModel = EmotionViewModel(player: player, delegate: viewController, difficultySetting: difficultySegControl.selectedSegmentIndex, numCorrectNeeded: Int((self.numberTextField.text?.isEmpty)! ? "1" : self.numberTextField.text!)!)
                viewController.viewModel = viewModel
            }
        }
    }
    
    @IBAction func showHelpDialog() {
        switch self.modalitySegControl.selectedSegmentIndex {
        case 0:
            let helpVC = UIViewController(nibName: "EquationHelpDialog", bundle: nil)
            let popup = PopupDialog(viewController: helpVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
            //let helpButton = DefaultButton(title: "CLOSE", height: 60, dismissOnTap: true, action: nil)
            //popup.addButton(helpButton)
            present(popup, animated: true, completion: nil)
        case 1:
            let helpVC = UIViewController(nibName: "EmotionHelpDialog", bundle: nil)
            let popup = PopupDialog(viewController: helpVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
            let helpButton = DefaultButton(title: "EXPRESSION EXAMPLES", height: 60, dismissOnTap: true, action: {
                let expressionVC = UIViewController(nibName: "ExpressionHelpDialog", bundle: nil)
                let popup2 = PopupDialog(viewController: expressionVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, gestureDismissal: true)
                self.present(popup2, animated: true, completion: nil)
            })
            popup.addButton(helpButton)
            
            present(popup, animated: true, completion: nil)
        default:
            break
        }
    }
    
    @IBAction func startTimer() {
        if !timerIsRunning {
            self.startAlarmButton.shake(count: 12, for: 1.51, withTranslation: 20)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ringTimer)), userInfo: nil, repeats: true)
            timerIsRunning = true
        }
    }
    
    @objc func ringTimer() {
        time -= 1
        if time == 0 {
            timer.invalidate()
            time = 3
            // start ringer
            timerIsRunning = false
            playTone()
        }
    }
    
    func playTone() {
        guard let url = Bundle.main.url(forResource: "Citrine", withExtension: "mp3") else {
            print("Error, unable to loud alarm tone")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            do {
                // Configure the audio session for speech +
                try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            } catch let error as NSError {
                print("Failed to set the audio session category and mode: \(error.localizedDescription)")
            }
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.modalitySegControl.selectedSegmentIndex == 0 ? self.performSegue(withIdentifier: "startEquationRecognizer", sender: nil) : self.performSegue(withIdentifier: "startEmotionGame", sender: nil)
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
}

extension MainAlarmViewController {
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.numberTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.numberTextField.resignFirstResponder()
    }
}
