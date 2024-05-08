import SwiftUI
import Model

struct DessertsListView: View {
  @EnvironmentObject var model: Model

  var body: some View {
    List(model.desserts) { item in
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
    .onAppear {
      if model.desserts.isEmpty {
        model.reloadDesserts()
      }
    }
  }
}

import MockServiceImplementations
#Preview {
  DessertsListView()
    .environmentObject(Model(services: .mock()))
}
