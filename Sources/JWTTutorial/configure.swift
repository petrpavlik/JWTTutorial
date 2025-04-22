import Fluent
import FluentSQLiteDriver
import JWT
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Add HMAC with SHA-256 signer.
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET environment variable not set")
    }
    await app.jwt.keys.add(hmac: .init(from: jwtSecret), digestAlgorithm: .sha256)

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateUser())

    // register routes
    try routes(app)
}
