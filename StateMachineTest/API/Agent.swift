//
//  Agent.swift
//  StateMachineTest
//
//  Created by Stephen Wall on 9/23/21.
//

import Foundation
import Combine

struct Agent {
  func run<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
    return URLSession.shared
      .dataTaskPublisher(for: request)
      .map { $0.data }
      .handleEvents(receiveOutput: { print(NSString(data: $0, encoding: String.Encoding.utf8.rawValue)!) })
      .decode(type: T.self, decoder: JSONDecoder())
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}
