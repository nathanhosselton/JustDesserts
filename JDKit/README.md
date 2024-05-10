# JDKit
A local Swift package providing custom interfaces for interacting with service data (both real and mocked) from our app target.

## Architecture
The package is split into separate modules to ensure proper encapsulation. The Model module defines the public interfaces required by the app and itself for populating and manipulating data. The services modules each implement a specific service interface as defined by the Model. Thus, the Model is imported by the services, but does not itself import the services.

This architecture also allows for individual services to be easily swapped with mocked counterparts, such as in the case of providing mocked data to SwiftUI Previews or to tests.

## Tests
The `ModelTests` target implements a small selection of basic tests of Model expectations. Test coverage is currently far from complete, so please take what is present as simply an example of potential direction for additional tests.
