//
//  CounterTest.swift
//  TourofTheBasicTCA_Counter
//
//  Created by Yin Bob on 2025/2/14.
//
import XCTest
import ComposableArchitecture
@testable import TourofTheBasicTCA_Counter

@MainActor
final class CounterTest: XCTestCase {
    func testCounter() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        await store.send(.incrementButtonTapped) {
            $0.count = 1
        }
    }
    
    func testTimer() async throws {
        let clock = TestClock()
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 1
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 2
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
}

