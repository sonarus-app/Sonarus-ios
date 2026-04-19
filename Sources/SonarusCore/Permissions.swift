import Foundation

public enum AuthorizationStatus: String, Codable, Sendable {
    case notDetermined
    case denied
    case authorized
    case restricted
}

public struct PermissionSnapshot: Codable, Sendable, Hashable {
    public var speechRecognition: AuthorizationStatus
    public var microphone: AuthorizationStatus

    public init(
        speechRecognition: AuthorizationStatus = .notDetermined,
        microphone: AuthorizationStatus = .notDetermined
    ) {
        self.speechRecognition = speechRecognition
        self.microphone = microphone
    }
}

public protocol PermissionsCoordinating: Sendable {
    func currentStatus() async -> PermissionSnapshot
    func requestPermissions() async -> PermissionSnapshot
}

public struct StubPermissionsCoordinator: PermissionsCoordinating {
    private let snapshot: PermissionSnapshot

    public init(snapshot: PermissionSnapshot = PermissionSnapshot(speechRecognition: .authorized, microphone: .authorized)) {
        self.snapshot = snapshot
    }

    public func currentStatus() async -> PermissionSnapshot {
        snapshot
    }

    public func requestPermissions() async -> PermissionSnapshot {
        snapshot
    }
}
