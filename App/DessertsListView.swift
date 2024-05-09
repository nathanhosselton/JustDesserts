import SwiftUI
import Model

/// The root view of the app displaying the list of desserts.
struct DessertsListView: View {
  /// The error received during the most recent call to `refresh()`, if any.
  @State private var lastError: Error? = nil
  /// Whether or not `lastError` should be presented when non-nil.
  @State private var shouldPresentError = false
  @EnvironmentObject var model: Model

  var body: some View {
    NavigationView {
      if !model.desserts.isEmpty {
        // - Desserts list
        List(model.desserts) { item in
          NavigationLink(destination: DessertDetailView(dessert: item)) {
            HStack {
              AsyncImage(url: item.thumbnail) { image in
                image.resizable()
                  .aspectRatio(1, contentMode: .fit)
              } placeholder: {
                Rectangle().overlay(Color.gray)
              }
              .frame(width: 100, height: 100)

              Text(item.name)
            }
          }
        }
        .refreshable {
          //TODO: If already refreshing, await current refresh
          await refresh()
        }
      } else if model.isFetchingDesserts {
        // Refreshing
        ProgressView()
      } else {
        // Refresh failed and retry was cancelled
        Button("Refresh") {
          Task { await refresh() }
        }
        .buttonStyle(.bordered)
      }
    }
    .task {
      await refresh()
    }
    .alert(isPresented: $shouldPresentError, error: lastError, actions: { _ in
      Button("OK") {}
      Button("Retry") {
        Task { await refresh() }
      }
    }, message: { error in
      Text(error.localizedDescription)
    })
  }

  /// Asks the `model` to refresh the contents of its `desserts`.
  ///
  /// If an error occurs, updates `lastError`. Calling this method again clears `lastError`.
  private func refresh() async {
    lastError = nil

    do {
      try await model.refreshDesserts()
      // View will invalidate on model change
    } catch {
      self.lastError = Error(title: "Couldn't fetch desserts", underlying: error)
      self.shouldPresentError = true
    }
  }

  private struct Error: LocalizedError {
    let title: String
    let underlying: Swift.Error

    var errorDescription: String? {
      title
    }

    var localizedDescription: String {
      underlying.localizedDescription
    }
  }
}

import MockServiceImplementations
#Preview {
  DessertsListView()
    .environmentObject(Model(services: .mock()))
}
