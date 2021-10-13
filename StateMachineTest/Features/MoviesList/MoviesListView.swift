//
//  MoviesListView.swift
//  StateMachineTest
//
//  Created by Stephen Wall on 9/23/21.
//

import SwiftUI

struct MoviesListView: View {
  @ObservedObject var viewModel = MoviesListViewModel()
  
  var body: some View {
    NavigationView {
      content
        .navigationTitle("Trending Movies")
    }
    .onAppear { self.viewModel.send(event: .onAppear) }
  }
  
  private var content: some View {
    switch viewModel.state {
    case .idle:
      return Color.clear.eraseToAnyView()
    case .loading:
      return Spinner(isAnimating: true, style: .large).eraseToAnyView()
    case .error(let error):
      return Text(error.localizedDescription).eraseToAnyView()
    case .loaded(let movies):
      return list(of: movies).eraseToAnyView()
    }
  }
  
  private func list(of movies: [MoviesListViewModel.ListItem]) -> some View {
    return List(movies) { movie in
      NavigationLink(
        destination: MovieDetailView(viewModel: MovieDetailViewModel(movieID: movie.id)),
        label: { MovieListItemView(movie: movie)}
      )
    }
  }
  
  struct MovieListItemView: View {
      let movie: MoviesListViewModel.ListItem
      @Environment(\.imageCache) var cache: ImageCache

      var body: some View {
          VStack {
              title
              poster
          }
      }
      
      private var title: some View {
          Text(movie.title)
              .font(.title)
              .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
      }
      
      private var poster: some View {
          movie.poster.map { url in
              AsyncImage(
                  url: url,
                  cache: cache,
                  placeholder: spinner,
                  configuration: { $0.resizable().renderingMode(.original) }
              )
          }
          .aspectRatio(contentMode: .fit)
          .frame(idealHeight: UIScreen.main.bounds.width / 2 * 3) // 2:3 aspect ratio
      }
      
      private var spinner: some View {
          Spinner(isAnimating: true, style: .medium)
      }
  }
  
}

struct MoviesListView_Previews: PreviewProvider {
  static var previews: some View {
    MoviesListView()
  }
}
