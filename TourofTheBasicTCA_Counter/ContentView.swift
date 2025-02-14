//
//  ContentView.swift
//  TourofTheBasicTCA_Counter
//
//  Created by Yin Bob on 2025/2/14.
//

import ComposableArchitecture
import SwiftUI

// 定義一個用於獲取數字相關事實的客戶端
struct NumberFactClient {
    var fetch: @Sendable (Int) async throws -> String
}

// 將 NumberFactClient 註冊為依賴項
extension NumberFactClient: DependencyKey {
    static let liveValue = Self { number in
        let (data, _) = try await URLSession.shared.data(from: URL(string: "http://www.numbersapi.com/\(number)")!
        )
        return String(decoding: data, as: UTF8.self)
    }
}

// 將 numberFact 添加到全局依賴容器中
extension DependencyValues {
    var numberFact: NumberFactClient {
        get { self[NumberFactClient.self] }
        set { self[NumberFactClient.self] = newValue }
    }
}

//MARK: 類似於 UIKit 中的 ViewModel
struct CounterFeature: Reducer {
    // 定義狀態，類似於 UIKit 中 ViewModel 的屬性
    struct State: Equatable {
        var count = 0
        var fact: String?
        var isLoadingFact = false
        var isTimerOn = false
    }
    
    // 定義所有可能的操作（類似於 UIKit 中 ViewModel 的方法）
    enum Action:Equatable {
        case decrementButtonTapped
        case factResponse(String)
        case getFactButtonTapped
        case incrementButtonTapped
        case timerTicked
        case toggleTimerButtonTapped
    }
    
    // 用於取消定時器的標識
    private enum CancelID {
        case timer
    }
    
    // 注入依賴
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFact
    
    // 核心邏輯處理（類似於 UIKit 中 ViewModel 的方法實現）
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                state.fact = nil
                return .none
                
            case let .factResponse(fact):
                state.fact = fact
                state.isLoadingFact = false
                return .none
                
            case .getFactButtonTapped:
                // TODO: perform network request
                state.fact = nil
                state.isLoadingFact = true
                // 發起網絡請求
                return .run { [count = state.count] send in
                    try await send(.factResponse(self.numberFact.fetch(count)))
                }
                
            case .incrementButtonTapped:
                state.count += 1
                state.fact = nil
                return .none
                
            case .timerTicked:
                state.count += 1
                return .none

            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                // TODO: start a timer
                if state.isTimerOn {
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1))
                        {
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
            }
        }
    }
}

// MARK: 類似於 UIKit 中的 ViewController
struct ContentView: View {
    // Store 是狀態容器，類似於 UIKit 中持有 ViewModel 的引用
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        // WithViewStore 用於將 Store 轉換為視圖可用的形式
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                // 計數器區域
                Section {
                    Text("\(viewStore.count)")
                    Button("Decrement") {
                        viewStore.send(.decrementButtonTapped)
                    }
                    Button("Increment") {
                        viewStore.send(.incrementButtonTapped)
                    }
                }
                
                // 獲取事實區域
                Section {
                    Button {
                        viewStore.send(.getFactButtonTapped)
                    } label: {
                        HStack {
                            Text("Get fact")
                            if viewStore.isLoadingFact {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    if let fact  = viewStore.fact {
                        Text(fact)
                    }
                }
                
                // 定時器控制區域
                Section {
                    if viewStore.isTimerOn {
                        Button("Stop timer") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    } else {
                        Button("Start timer") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: CounterFeature.State()) {
            CounterFeature()
                ._printChanges()
        }
    )
}


/*
 程式碼範例：https://www.pointfree.co/episodes/ep243-tour-of-the-composable-architecture-1-0-the-basics
 */
