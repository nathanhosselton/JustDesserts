import SwiftUI
import Model
import ServiceImplementations

@main
struct JustDessertsApp: App {
  @StateObject var model = Model(services: Services())

  var body: some Scene {
    WindowGroup {
      DessertsListView()
        .environmentObject(model)
    }
  }
}
