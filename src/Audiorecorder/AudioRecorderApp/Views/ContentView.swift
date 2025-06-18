//
//  ContentView.swift
//  Audiorecorder
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 50) {
            AudioRecorderView()
            Divider()
            AudioPlayerView()
        }
        .padding()
    }
}
