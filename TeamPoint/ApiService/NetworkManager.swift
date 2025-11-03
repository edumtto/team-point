//
//  NetworkManager.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

// TODO
/*
import Foundation

final class NetworkManager {
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case serverError(statusCode: Int, message: String?)
        case decodingError(Error)
    }

    /// Performs a generic network request and decodes the response into a specified Decodable type.
    /// - Parameters:
    ///   - url: The full URL for the API request.
    /// - Returns: An instance of the decoded type T.
    func request<T: Decodable>(url: URL) async throws -> T {
        print("NetworkManager: Attempting to fetch from: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("NetworkManager: Server returned status code: \(httpResponse.statusCode)")
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }

        let decoder = JSONDecoder()
        do {
            let decodedObject = try decoder.decode(T.self, from: data)
            print("NetworkManager: Successfully decoded response for \(T.self)")
            return decodedObject
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
*/
