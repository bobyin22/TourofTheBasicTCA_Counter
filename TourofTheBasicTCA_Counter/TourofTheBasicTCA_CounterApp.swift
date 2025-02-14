//
//  TourofTheBasicTCA_CounterApp.swift
//  TourofTheBasicTCA_Counter
//
//  Created by Yin Bob on 2025/2/14.
//

import ComposableArchitecture
import SwiftUI


@main
struct TourofTheBasicTCA_CounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(initialState: CounterFeature.State()) {
                    CounterFeature()
                }
            )
        }
    }
}
