# JustDesserts
The complete iOS codebase for "JustDesserts", a SwiftUI app which fetches desserts and their details from [themealdb.com](https://www.themealdb.com) for browsing by a user.

This project was created as an interview exercise.

## Dependencies
This project bundles a single library, [JDKit](JDKit/), which encapsulates the app's model and services layers, and which is locally maintained in the project. The library is managed by Swift Package Manager and will build automatically with the project.

## Architecture
Because this app is simple, its architecture was also kept simple, following natural SwiftUI patterns of data flow. A single `Model` instance is created and held as an environment object by the app, and views access it be declaring a reference to it.

## Mocks
This app supports mocked data in SwiftUI Previews. No configuration is required; simply run the Preview of a particular view to interact with its UI in isolation. Run the app in a simulator or on a physical device to see live data.

## Tests
See the [JDKit README](JDKit/README.md).
