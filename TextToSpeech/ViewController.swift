//
//  ViewController.swift
//  TextToSpeech
//
//  Created by Luciano Nunes on 12/04/2018.
//  Copyright © 2018 Luciano Nunes. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {

    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var readButton: UIButton!
    
    //public var item: OMGFeedItem?
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance = AVSpeechUtterance(string: "")
    
    var totalUtterances: Int! = 0
    var currentUtterance: Int! = 0
    var totalTextLength: Int = 0
    var spokenTextLengths: Int = 0
    
    var previousSelectedRange: NSRange!
    
    var isReading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        speechSynthesizer.delegate = self
        
        setInitialFontAttribute()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AVSpeechSynthesizerDelegate Methods
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        spokenTextLengths = spokenTextLengths + utterance.speechString.count + 1
        
        if currentUtterance == totalUtterances {
            
            unselectLastWord()
            previousSelectedRange = nil
        }
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
        currentUtterance = currentUtterance + 1
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        
        // Determine the current range in the whole text (all utterances), not just the current one.
        let rangeInTotalText = NSMakeRange(spokenTextLengths + characterRange.location, characterRange.length)
        
        // Select the specified range in the textfield.
        contentTextView.selectedRange = rangeInTotalText
        
        // Store temporarily the current font attribute of the selected text.
        let currentAttributes = contentTextView.attributedText.attributes(at: rangeInTotalText.location, effectiveRange: nil)
        let fontAttribute: AnyObject? = currentAttributes[NSAttributedStringKey.font] as AnyObject
        
        // Assign the selected text to a mutable attributed string.
        let attributedString = NSMutableAttributedString(string: contentTextView.attributedText.attributedSubstring(from: rangeInTotalText).string)
        
        // Make the text of the selected area orange by specifying a new attribute.
        attributedString.addAttribute(.foregroundColor, value: UIColor.orange, range: NSMakeRange(0, attributedString.length))
        
        // Make sure that the text will keep the original font by setting it as an attribute.
        attributedString.addAttribute(.font, value: fontAttribute!, range: NSMakeRange(0, attributedString.string.count))
        
        // In case the selected word is not visible scroll a bit to fix this.
        contentTextView.scrollRangeToVisible(rangeInTotalText)
        
        // Begin editing the text storage.
        contentTextView.textStorage.beginEditing()
        
        // Replace the selected text with the new one having the orange color attribute.
        contentTextView.textStorage.replaceCharacters(in: rangeInTotalText, with: attributedString)
        
        // If there was another highlighted word previously (orange text color), then do exactly the same things as above and change the foreground color to black.
        if let previousRange = previousSelectedRange {
            
            let previousAttributedText = NSMutableAttributedString(string: contentTextView.attributedText.attributedSubstring(from: previousRange).string)
            previousAttributedText.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, previousAttributedText.length))
            previousAttributedText.addAttribute(.font, value: fontAttribute!, range: NSMakeRange(0, previousAttributedText.length))
            
            contentTextView.textStorage.replaceCharacters(in: previousRange, with: previousAttributedText)
        }
        
        // End editing the text storage.
        contentTextView.textStorage.endEditing()
        
        // Keep the currently selected range so as to remove the orange text color next.
        previousSelectedRange = rangeInTotalText
    }
    
    //MARK: - Helper Methods
    
    func setInitialFontAttribute() {
        
        let rangeOfWholeText = NSMakeRange(0, contentTextView.text.count)
        let attributedText = NSMutableAttributedString(string: contentTextView.text)
        attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "Arial", size: 18.0)!, range: rangeOfWholeText)
        contentTextView.textStorage.beginEditing()
        contentTextView.textStorage.replaceCharacters(in: rangeOfWholeText, with: attributedText)
        contentTextView.textStorage.endEditing()
    }
    
    func unselectLastWord() {
        
        if let selectedRange = previousSelectedRange {
            
            // Get the attributes of the last selected attributed word.
            let currentAttributes = contentTextView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
            // Keep the font attribute.
            let fontAttribute: AnyObject? = currentAttributes[NSAttributedStringKey.font] as AnyObject
            
            // Create a new mutable attributed string using the last selected word.
            let attributedWord = NSMutableAttributedString(string: contentTextView.attributedText.attributedSubstring(from: selectedRange).string)
            
            // Set the previous font attribute, and make the foreground color black.
            attributedWord.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, attributedWord.length))
            attributedWord.addAttribute(.font, value: fontAttribute!, range: NSMakeRange(0, attributedWord.length))
            
            // Update the text storage property and replace the last selected word with the new attributed string.
            contentTextView.textStorage.beginEditing()
            contentTextView.textStorage.replaceCharacters(in: selectedRange, with: attributedWord)
            contentTextView.textStorage.endEditing()
        }
    }
    
    //MARK: - Button Clicked
    
    @IBAction func readButtonClicked(_ sender: Any) {
        
        if isReading {
            
            readButton.setTitle("Play", for: .normal)
            
            speechSynthesizer.pauseSpeaking(at: .word)
            
        } else {
            
            readButton.setTitle("Pause", for: .normal)
            
            if  speechSynthesizer.isPaused {
                
                speechSynthesizer.continueSpeaking()
                
            } else {
                
                let textParagraphs = contentTextView.text.components(separatedBy: "\n")
                
                totalUtterances = textParagraphs.count
                currentUtterance = 0
                totalTextLength = 0
                spokenTextLengths = 0
                
                for pieceOfText in textParagraphs {
                    let speechUtterance = AVSpeechUtterance(string: pieceOfText)
                    speechUtterance.rate = 0.55
                    speechUtterance.pitchMultiplier = 0.25
                    speechUtterance.volume = 0.75
                    speechUtterance.postUtteranceDelay = 0.005
                    
                    totalTextLength = totalTextLength + pieceOfText.count
                    
                    speechSynthesizer.speak(speechUtterance)
                }
            }
        }
        
        isReading = !isReading
    }

}

