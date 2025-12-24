//
//  mad_applicationTests.swift
//  mad_applicationTests
//
//  Created by Павел on 13.12.2025.
//

import Foundation
import Testing
@testable import mad_application

struct LLMClientTests {
    @Test func httpErrorMapperThrowsOnServerError() async throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data("Internal error".utf8)
        await #expect(throws: URLError.self) {
            try HTTPErrorMapper.throwIfNeeded(response: response, data: data)
        }
    }

    @Test func httpErrorMapperPassesSuccessfulResponse() async throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()
        try HTTPErrorMapper.throwIfNeeded(response: response, data: data)
    }
}
