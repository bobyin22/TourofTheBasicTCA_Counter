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
    // 類似於在 UIKit 中初始化 ViewModel
    func testCounter() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        // 在 UIKit 中可能是這樣：
        // viewModel.incrementButtonTapped()
        // XCTAssertEqual(viewModel.count, 1)
        await store.send(.incrementButtonTapped) {
            $0.count = 1
        }
    }
    
    func testTimer() async throws {
        // 創建模擬時鐘，類似於在 UIKit 中 mock Timer
        let clock = TestClock()
        
        // 創建 store 並注入模擬時鐘
        // 類似於 UIKit 中的依賴注入：
        // viewModel.timer = mockTimer
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock  // 注入測試時鐘
        }
        
        // 模擬啟動定時器
        // UIKit: viewModel.startTimer()
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        
        // 模擬時間前進 1 秒
        // 模擬時間流逝
        // UIKit 中很難測試，需要等待真實時間
        await clock.advance(by: .seconds(1))
        // 驗證接收到定時器滴答事件，並且計數增加
        // UIKit: XCTAssertEqual(viewModel.count, 1)
        await store.receive(.timerTicked) {
            $0.count = 1
        }
        
        // 再次模擬時間前進 1 秒
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTicked) {
            $0.count = 2
        }
        
        // 停止定時器
        // UIKit: viewModel.stopTimer()
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
    
    // 測試獲取數字事實功能（成功情況）
    func testGetFact() async {
        // 創建 store 並注入模擬的網絡服務
        // 類似於 UIKit 中：
        // viewModel.networkService = mockNetworkService
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            // 注入模擬的 numberFact 服務
            $0.numberFact.fetch = { "\($0) is a great number!" }
        }
        
        // 模擬點擊獲取按鈕
        // UIKit: viewModel.getFact()
        await store.send(.getFactButtonTapped) {
            $0.isLoadingFact = true
        }
        
        // 驗證網絡請求完成後的狀態
        // UIKit 中需要使用 expectation 等待異步操作
        await store.receive(.factResponse("0 is a great number!")) {
            $0.fact = "0 is a great number!"
            $0.isLoadingFact = false
        }
    }
    
    func testGetFact_Failure() async {
        // 注入會失敗的模擬網絡服務
        // UIKit: viewModel.networkService = failingMockNetworkService
      let store = TestStore(initialState: CounterFeature.State()) {
        CounterFeature()
      } withDependencies: {
          // 注入會拋出錯誤的模擬服務
        $0.numberFact.fetch = { _ in
          struct SomeError: Error {}
          throw SomeError()
        }
      }
        
      // 標記這個測試預期會失敗
      XCTExpectFailure()
        
      // 模擬點擊按鈕
      await store.send(.getFactButtonTapped) {
        $0.isLoadingFact = true
      }
    }
}

