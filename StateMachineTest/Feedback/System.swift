//
//  System.swift
//  StateMachineTest
//
//  Created by Stephen Wall on 9/23/21.
//

import Combine
import SwiftUI

extension Publishers {
  
  static func system<State, Event, Scheduler: Combine.Scheduler>(
    initial: State,
    reduce: @escaping (State, Event) -> State,
    scheduler: Scheduler,
    feedbacks: [Feedback<State, Event>]
  ) -> AnyPublisher<State, Never> {
    
    let state = CurrentValueSubject<State, Never>(initial)
    
    let events = feedbacks.map { feedback in feedback.run(state.eraseToAnyPublisher()) }
    
    return Deferred {
      Publishers.MergeMany(events)
        .receive(on: scheduler)
        .scan(initial, reduce)
        .handleEvents(receiveOutput: state.send)
        .receive(on: scheduler)
        .prepend(initial)
    }
    .eraseToAnyPublisher()
  }
}
