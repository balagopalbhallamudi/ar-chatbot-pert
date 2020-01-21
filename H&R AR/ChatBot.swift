//
//  ChatBot.swift
//  H&R AR
//
//  Created by Bhanuka Gamage on 1/18/20.
//  Copyright © 2020 Bhanuka Gamage. All rights reserved.
//

import Foundation
import AVFoundation

class ChatBot {
  let session = URLSession.shared
  var speechSynthesizer = AVSpeechSynthesizer()
  // var replies = ["Hi", "I am bhanukee", "Oh nice to meet you",
  //                 "You're handsome too", "oi you creep",
  //                 "CREEP BHANUKA", "I tell your girlfriend",
  //                 "k bye", "No come back"]
  init() {
  }

  /**
   * @param text: Input string to be said out loud
   */
  func textToSpeech(text: String) -> Void {
    let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
    speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
    speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    self.speechSynthesizer.speak(speechUtterance)
  }

  /**
   * @param input: Input string by the user to talk to the chatbot
   * @return: Reply by the chatbot
   */
    func talk(input: String, completed: @escaping (String) -> ()) -> Void {
    var str: String = ""
    
    let encoded = input.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        if let encodedString = encoded{
            let final = "http://172.23.153.71:8000/api/text=\(encodedString)"
            
            if let url = URL(string: final) {
                
                let task = self.session.dataTask(with: url) { data, response, error in
                  if error != nil {
                    
                  } else {
                    str = String(decoding: data ?? Data(), as: UTF8.self)
                    DispatchQueue.main.async {
                        completed(str)
                    }
                  }
                }
                task.resume()
            } else {
                print("failed")
            }
            
            
        }
    

        
    

  }
}
