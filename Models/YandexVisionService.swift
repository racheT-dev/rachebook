// YandexVisionService.swift
import UIKit

// Свой Result для старых версий Swift (< 5.0)
enum MyResult<T> {
    case success(T)
    case failure(Error)
}

class YandexVisionService {
    private let apiKey = ""
    private let folderId = ""
    private let url = URL(string: "https://ocr.api.cloud.yandex.net/ocr/v1/recognizeText")!
    
    func recognizeHandwrittenText(from image: UIImage,
                                  completion: @escaping (MyResult<String>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            completion(.failure(ServiceError.imageConversionFailed))
            return
        }
        
        let base64Content = imageData.base64EncodedString()
        
        let body: [String: Any] = [
            "mimeType": "JPG",
            "languageCodes": ["ru"],
            "model": "handwritten",
            "content": base64Content
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(ServiceError.jsonSerializationFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(folderId, forHTTPHeaderField: "x-folder-id")
        request.setValue("true", forHTTPHeaderField: "x-data-logging-enabled")
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let errorMessage = "HTTP \(statusCode)"
                    completion(.failure(ServiceError.serverError(message: errorMessage)))
                    return
            }
            
            guard let data = data else {
                completion(.failure(ServiceError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let result = json["result"] as? [String: Any],
                    let textAnnotation = result["textAnnotation"] as? [String: Any],
                    let fullText = textAnnotation["fullText"] as? String {
                    completion(.success(fullText))
                } else {
                    completion(.failure(ServiceError.parsingError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

enum ServiceError: LocalizedError {
    case imageConversionFailed
    case jsonSerializationFailed
    case serverError(message: String)
    case noData
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Не удалось преобразовать изображение"
        case .jsonSerializationFailed: return "Ошибка формирования запроса"
        case .serverError(let msg): return "Ошибка сервера: \(msg)"
        case .noData: return "Сервер не вернул данные"
        case .parsingError: return "Не удалось разобрать ответ"
        }
    }
}
