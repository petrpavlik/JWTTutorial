import JWT
import Vapor

struct SessionToken: Authenticatable, JWTPayload {

    // Constants
    static let expirationTime: TimeInterval = 60 * 15

    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID

    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Self.expirationTime))
    }

    init(with user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Self.expirationTime))
    }

    func verify(using algorithm: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
