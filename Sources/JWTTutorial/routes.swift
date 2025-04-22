import Fluent
import Vapor

struct ClientTokenResponse: Content {
    var token: String
}

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.post("login") { req async throws -> ClientTokenResponse in

        struct LoginRequestBody: Content, Validatable {
            let email: String
            let password: String

            static func validations(_ validations: inout Vapor.Validations) {
                validations.add("email", as: String.self, is: .email)
                validations.add("password", as: String.self, is: !.empty)
            }
        }

        try LoginRequestBody.validate(content: req)
        let data = try req.content.decode(LoginRequestBody.self)

        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == data.email.lowercased())
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        guard try Bcrypt.verify(data.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // Validate provided credential for user
        // Get userId for provided user
        let payload = try SessionToken(userId: user.requireID())

        // TODO: implement refresh tokens
        return ClientTokenResponse(token: try await req.jwt.sign(payload))
    }

    app.post("register") { req async throws -> ClientTokenResponse in

        struct RegisterRequestBody: Content, Validatable {
            let email: String
            let password: String

            static func validations(_ validations: inout Vapor.Validations) {
                validations.add("email", as: String.self, is: .email)
                validations.add("password", as: String.self, is: .count(4...))
            }
        }

        try RegisterRequestBody.validate(content: req)
        let data = try req.content.decode(RegisterRequestBody.self)

        let user = User(
            email: data.email.lowercased(), passwordHash: try Bcrypt.hash(data.password))
        try await user.save(on: req.db)

        // Validate provided credential for user
        // Get userId for provided user
        let payload = try SessionToken(userId: user.requireID())

        // TODO: implement refresh tokens
        return ClientTokenResponse(token: try await req.jwt.sign(payload))
    }

    // Create a route group that requires the SessionToken JWT.
    let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())

    // Return ok reponse if the user-provided token is valid.
    secure.get("me") { req -> HTTPStatus in
        let sessionToken = try req.auth.require(SessionToken.self)
        print(sessionToken.userId)
        return .ok
    }

}
