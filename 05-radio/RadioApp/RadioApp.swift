//
//  RadioApp.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI
import AVFoundation

@main
struct RadioApp: App {
    
    init() {
        // Configure audio session for background playback
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeV()
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
