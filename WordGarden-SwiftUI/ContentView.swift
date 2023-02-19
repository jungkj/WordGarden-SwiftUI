//
//  ContentView.swift
//  WordGarden-SwiftUI
//
//  Created by Andy Jung on 2/12/23.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var revealedWord = ""
    @State private var lettersGuessed = ""
    @State private var guessesRemaining = 8
    @State private var gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
    @State private var guessedLetter = ""
    @State private var imageName = "flower8"
    @State private var playAgainHidden = true
    @State private var playAgainButtonLabel = "Another Word?"
    @State private var audioPlayer: AVAudioPlayer!
    @FocusState private var textFieldIsFocused: Bool
    
    
    private let wordsToGuess = ["SWIFT", "DOG", "CAT"]
    private let maximumGuesses = 8
    
    var body: some View {
        VStack{
            HStack{
                VStack (alignment: .leading){
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                
                VStack (alignment: .trailing){
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            Spacer()
            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()
            
            Spacer()
            
            //TODO: Switch to wordsToGuess[currentWord]
            Text(revealedWord)
                .font(.title)
            
            if playAgainHidden{
                HStack{
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay{
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) { _ in
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last else{
                                return
                            }
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .onSubmit {
                            guard guessedLetter != "" else {
                                return
                            }
                            guessALetter()
                            updateGamePlay()
                        }
                        .focused($textFieldIsFocused)
                    
                    Button("Guess a Letter"){
                        guessALetter()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            }else{
                
                Button(playAgainButtonLabel){
                    // If all words have been guessed...
                    if currentWordIndex == wordsToGuess.count{
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another Word?"
                    }
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(repeating: " _", count: wordToGuess.count-1)
                    lettersGuessed = ""
                    guessesRemaining = maximumGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
                    playAgainHidden = true
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            Spacer()
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imageName)
            
            
        }
        .ignoresSafeArea(edges:.bottom)
        .onAppear(){
            wordToGuess = wordsToGuess[currentWordIndex]
            revealedWord = "_" + String(repeating: " _", count: wordToGuess.count-1)
            guessesRemaining = maximumGuesses
        }
    }
    func guessALetter(){
        //TODO: Guess a Letter Button Action here
        textFieldIsFocused = false
        lettersGuessed = lettersGuessed + guessedLetter
        
        revealedWord = ""
        // loop thru all letters in wordToGuess
        for letter in wordToGuess{
            // check if letter in wordToGuess is in lettersGuessed (i.e. did you guess this letter already?
            if lettersGuessed.contains(letter){
                revealedWord = revealedWord + "\(letter) "
            } else {
                // if not, add an iunderscore + a blank space, to revealedWord
                revealedWord = revealedWord + "_ "
            }
        }
        revealedWord.removeLast()
    }
    
    func updateGamePlay(){
        if !wordToGuess.contains(guessedLetter){
            guessesRemaining -= 1
            // Animate crumbling leaf and play "incorrect" sound
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            
            // Delay change to flower image until after wilt animation is done
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                imageName = "flower\(guessesRemaining)"
            }
        } else {
            playSound(soundName: "correct")
        }
        
        if !revealedWord.contains("_") {
            //Guessed when no _ in revealedWord
            gameStatusMessage = "You've Guessed it! It Took You \(lettersGuessed.count) Guesses to Guess the Word."
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed")
        } else if guessesRemaining == 0 { //Words Missed
            gameStatusMessage = "So Sorry. You Are All Out of Guesses."
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
            
        }else{ // Keep guessing
            gameStatusMessage = "You've Made \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es")"
        }
        if currentWordIndex == wordsToGuess.count {
            playAgainButtonLabel = "Restart Game?"
            gameStatusMessage = gameStatusMessage + "\nYou've Tried All the Words. Restart from the beginning?"
        }
        guessedLetter = ""
    }
    
    func playSound(soundName: String){
        guard let soundFile = NSDataAsset(name: soundName) else{
            print("😡 Could not read file named \(soundName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch{
            print("😡 ERROR: \(error.localizedDescription) creating audioPlayer.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
