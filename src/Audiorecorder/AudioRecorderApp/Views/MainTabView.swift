//
//  MainTabView.swift
//  Audiorecorder
//
//  Created by Administrator on 18.06.25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Aufnahme
            AudioRecorderView()
                .tabItem {
                    Label("Recorder", systemImage: "recordingtape")
                }
            
            // Abspielen
            AudioPlayerView()
                .tabItem {
                    Label("Player", systemImage: "play.circle")
                }
            
        }
    }
}
