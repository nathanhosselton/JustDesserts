import Foundation

/// Represents an error which can occur within the Model.
public enum ModelError: Swift.Error {
  /// Indicates that the Model encountered a permanent failure while trying to provide requested data.
  ///
  /// This can occur when local expectations have not yet accounted for a response in the format received
  /// and is generally unrecoverable. A standard `localizedDescription` is available for user display
  /// though it is recommended that this error be detected and handled gracefully where possible.
  ///
  //TODO: Occurrences of this error should be forwarded to our bug report service.
  case permanentResponseFailure

  public var localizedDescription: String {
    switch self {
    case .permanentResponseFailure:
      "Something went wrong and it's unlikely that retrying will help. Please contact support for assistance."
    }
  }
}

/// An Error type representing specific failures that a `NetworkService` is expected to communicate.
public enum NetworkServiceError: Error {
  /// The request timed out before it could complete. This is most often a result of poor network connectivity,
  /// though it may also indicate a service disruption when widespread.
  case timeout
  /// The request did not complete due to total connectivity failure of the device.
  case connectivity
  /// The service was unable to handle the request because it is down or it encountered an unrecoverable
  /// error while processing.
  case serviceUnavailable
  /// A network failure occurred with a status code that does not currently map to a specific user-facing reason.
  case other(statusCode: Int)
  /// An error which does not yet have a concrete representation on this type. The error's `localizedDescription`
  /// will be automatically included in the `message`.
  case unknownUnhandled(Error)

  public var localizedDescription: String {
    switch self {
    case .timeout:
      return "The communication remained idle for too long and timed out. Verify your cellular or wifi service and try again."
    case .connectivity:
      return "The communication was stopped due to a connectivity failure. Verify your cellular or wifi service and try again."
    case .serviceUnavailable:
      return "The service is unavailable. Please wait and try again. If this issue persists, contact support."
    case .other(let statusCode):
      return "The request couldn't be completed (code: \(statusCode)). Please try again. If this issue persists, contact support."
    case .unknownUnhandled(let error):
      return "Something went wrong. We've included what we know below in case it's helpful. If this issue persists, please contact support.\n\n\(error.localizedDescription)"
    }
  }
}
