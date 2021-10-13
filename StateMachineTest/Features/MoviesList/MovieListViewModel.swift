//
//  MovieListViewModel.swift
//  StateMachineTest
//
//  Created by Stephen Wall on 9/23/21.
//

import Foundation
import Combine

final class MoviesListViewModel: ObservableObject {
  @Published private(set) var state = State.idle
  private var bag = Set<AnyCancellable>()
  private let input = PassthroughSubject<Event, Never>()
  
  // 1. MoviesListViewModel is the entry point of the feature. It connects all the dependencies and starts the state machine.
  // 2. The whenLoading() feedback handles networking. We’ll implement it in a moment.
  // 3. The send() method provides a way of passing user input and view lifecycle events.
  //    Using the input subject, we propagate the events into the feedback loop for processing.
  init() {
    // 1.
    Publishers.system(
      initial: state,
      reduce: Self.reduce,
      scheduler: RunLoop.main,
      feedbacks: [
        // 2.
        Self.whenLoading(),
        Self.userInput(input: input.eraseToAnyPublisher())
      ]
    )
    .assign(to: \.state, on: self)
    .store(in: &bag)
  }
  
  deinit {
    bag.removeAll()
  }
  
  // 3.
  func send(event: Event) {
    input.send(event)
  }
}

// MARK: - Inner Types
extension MoviesListViewModel {
  enum State {
    case idle
    case loading
    case loaded([ListItem])
    case error(Error)
  }
  
  enum Event {
    case onAppear
    case onSelectMovie(Int)
    case onMoviesLoaded([ListItem])
    case onFailedToLoadMovies(Error)
  }
  
  struct ListItem: Identifiable {
    let id: Int
    let title: String
    let poster: URL?
    
    init(movie: MovieDTO) {
      self.id = movie.id
      self.title = movie.title
      self.poster = movie.poster
    }
  }
}

// MARK: - State Machine
// FCM - Finite State Machine
extension MoviesListViewModel {
  /// This function defines all possible state-to-state transitions
  /// - Parameters:
  ///   - state: Current MoviesListViewModel.State
  ///   - event: MoviesListViewModel.Event you want to inflict on the current state.
  /// - Returns: MoviesListViewModel.State that is the result of the event.
  static func reduce(_ state: State, _ event: Event) -> State {
    switch state {
    case .idle:
      switch event {
      case .onAppear: return .loading
      default: return state
      }
    case .loading:
      switch event {
      case .onMoviesLoaded(let movies): return .loaded(movies)
      case .onFailedToLoadMovies(let error): return .error(error)
      default: return state
      }
    case .loaded: return state
    case .error: return state
    }
  }
  
  // 1. Check that the system is currently in the loading state.
  // 2. Fire a network request.
  // 3. In case the request succeeds, the feedback sends an onMoviesLoaded event with a list of movies.
  // 4. In case of a failure, the feedback sends an onFailedToLoadMovies event with an error.

  /// When the system enters the loading state, we initiate a network request:
  /// - Returns: Feedback with the new state
  static func whenLoading() -> Feedback<State, Event> {
    Feedback { (state: State) -> AnyPublisher<Event, Never> in
      // 1.
      guard case .loading = state else { return Empty().eraseToAnyPublisher() }
      // 2.
      return MoviesAPI.trending()
        .map { $0.results.map(ListItem.init) }
        // 3.
        .map(Event.onMoviesLoaded)
        // 4.
        .catch { Just(Event.onFailedToLoadMovies($0)) }
        .eraseToAnyPublisher()
    }
  }
}

extension MoviesListViewModel {
  // On the state machine figure, you can see all the events except for onSelectMovie.
  // The reason for that is because onSelectMovie is sent as a result of user interaction with an app.
  // User input is a side effect that needs to be handled inside feedback:
  static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
    Feedback { _ in input }
  }
}
