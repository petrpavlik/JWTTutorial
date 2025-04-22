import Fluent
import Testing
import VaporTesting

@testable import JWTTutorial

@Suite("App Tests with DB", .serialized)
struct JWTTutorialTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    // @Test("Getting all the Todos")
    // func getAllTodos() async throws {
    //     try await withApp { app in
    //         let sampleTodos = [Todo(title: "sample1"), Todo(title: "sample2")]
    //         try await sampleTodos.create(on: app.db)

    //         try await app.testing().test(.GET, "todos", afterResponse: { res async throws in
    //             #expect(res.status == .ok)
    //             #expect(try res.content.decode([TodoDTO].self) == sampleTodos.map { $0.toDTO()} )
    //         })
    //     }
    // }

    @Test("Creating a user")
    func createUser() async throws {
        let credentials = ["email": "user1@example.com", "password": "password"]

        try await withApp { app in
            try await app.testing().test(
                .POST, "register",
                beforeRequest: { req in
                    try req.content.encode(credentials)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    _ = try res.content.decode(ClientTokenResponse.self)
                })
        }
    }

    @Test("Logging a user in")
    func loginUser() async throws {

        let credentials = ["email": "user1@example.com", "password": "password"]

        try await withApp { app in
            
            try await app.testing().test(
                .POST, "register",
                beforeRequest: { req in
                    try req.content.encode(credentials)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    _ = try res.content.decode(ClientTokenResponse.self)
                })
            
            try await app.testing().test(
                .POST, "login",
                beforeRequest: { req in
                    try req.content.encode(credentials)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    _ = try res.content.decode(ClientTokenResponse.self)
                })
        }
    }
    
    @Test("Accessing route behind auth")
    func accessUser() async throws {

        let credentials = ["email": "user1@example.com", "password": "password"]

        try await withApp { app in
            
            try await app.testing().test(
                .POST, "register",
                beforeRequest: { req in
                    try req.content.encode(credentials)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    _ = try res.content.decode(ClientTokenResponse.self)
                })
            
            var token: String!
            
            try await app.testing().test(
                .POST, "login",
                beforeRequest: { req in
                    try req.content.encode(credentials)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(ClientTokenResponse.self)
                    token = data.token
                })
            
            try await app.testing().test(
                .GET, "me",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                })
                
        }
    }

}
