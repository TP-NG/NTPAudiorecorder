//
//  LooperView.swift
//  Audiorecorder
//

import SwiftUI

// MARK: - Looper View
struct LooperView: View {
    @ObservedObject var audioRecorder: AudioRecorderManager
    @State private var showingRenameDialog = false
    @State private var renameIndex = 0
    @State private var newTitle = ""
    
    var body: some View {
        VStack {
            RecorderView(audioRecorder: audioRecorder)
                .transition(.move(edge: .leading))
           
            // Looper-Funktion, Metronom und Count-In 
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}


// MARK: SubView

