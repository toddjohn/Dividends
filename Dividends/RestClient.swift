//
//  RestClient.swift
//  Dividends
//
//  Created by Todd Johnson on 12/19/18.
//  Copyright © 2018 Todd Johnson. All rights reserved.
//

import Foundation

public enum HttpMethod: String {
    case Get = "GET"
    case Post = "POST"
    case Put = "PUT"
    case Delete = "DELETE"
}

public enum ContentType: String {
    case JSON = "application/json"
    case JPEG = "image/jpeg"
}

private func identifyError(_ code: Int, details: String?) -> NSError {
    var userInfo: [String: Any] = [:]
    switch code {
    case 300...399:
        userInfo[NSLocalizedDescriptionKey] = "Response was redirected: \(code)"
    case 400...499:
        userInfo[NSLocalizedDescriptionKey] = "Client error: \(code)"
    case 500...599:
        userInfo[NSLocalizedDescriptionKey] = "Server error: \(code)"
    default:
        userInfo[NSLocalizedDescriptionKey] = "Unknown error: \(code)"
    }
    userInfo[NSLocalizedFailureReasonErrorKey] = details ?? "No details from server"

    let error = NSError(domain: "com.intel.restclient", code: code, userInfo: userInfo)
    return error
}

internal class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var progressUpdate: ((_ progress: Float) -> ())?
    var success: ((_ data: URL) -> ())?
    var failure: ((_ error: NSError) -> ())?

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // note: this is called with error == nil when download completes successfully
        if let error = error {
            print("download failed: \(error.localizedDescription)")
            self.failure?(error as NSError)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let response = downloadTask.response as? HTTPURLResponse {
            if 200...299 ~= response.statusCode {
                print("download complete for \(location.absoluteString)")
                self.success?(location)
            } else {
                print("download failed: http status = \(response.statusCode)")
                let serverInfo = "No details from server"
                let responseError = identifyError(response.statusCode, details: serverInfo)
                self.failure?(responseError)
            }
        } else {
            let serverInfo = "No details from server"
            let responseError = identifyError(-1, details: serverInfo)
            self.failure?(responseError)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("downloaded \(bytesWritten) bytes (\(totalBytesWritten) total) out of \(totalBytesExpectedToWrite)")
        var percentComplete: Float = 0
        if totalBytesExpectedToWrite > 0 {
            percentComplete = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        }
        self.progressUpdate?(percentComplete)
    }
}

internal class UploadDelegate: NSObject, URLSessionTaskDelegate {
    var progressUpdate: ((_ progress: Float) -> ())?
    var success: (() -> ())?
    var failure: ((_ error: NSError) -> ())?

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // note: this is called with error == nil when download completes successfully
        if let error = error {
            print("upload failed: \(error.localizedDescription)")
            self.failure?(error as NSError)
        } else {
            if let response = task.response as? HTTPURLResponse {
                if 200...299 ~= response.statusCode {
                    print("upload completed without error")
                    success?()
                } else {
                    print("upload failed: http status = \(response.statusCode)")
                    let serverInfo = "No details from server"
                    let responseError = identifyError(response.statusCode, details: serverInfo)
                    self.failure?(responseError)
                }
            } else {
                let serverInfo = "No details from server"
                let responseError = identifyError(-1, details: serverInfo)
                self.failure?(responseError)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("uploaded \(bytesSent) bytes (\(totalBytesSent) total) out of \(totalBytesExpectedToSend)")
        var percentComplete: Float = 0
        if totalBytesExpectedToSend > 0 {
            percentComplete = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        }
        self.progressUpdate?(percentComplete)
    }
}

open class RestClient {
    open var host = "http://localhost:8080"
    public static let client = RestClient()
    open var token: String?
    fileprivate var session: URLSession

    fileprivate init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }

    fileprivate func sendRequest(_ request: NSMutableURLRequest, method: HttpMethod,
                                 success: @escaping (_ object: AnyObject?) -> (),
                                 failure: @escaping (_ error: NSError) -> (),
                                 successWithData: ((_ data: Data) -> ())? = nil) {
        request.httpMethod = method.rawValue
        var requestLogMessage = "Sending request: \(method.rawValue) \(request.url!.absoluteString)\nHeaders:\n"
        if let headers = request.allHTTPHeaderFields {
            requestLogMessage = requestLogMessage + "\(headers)"
        }
        if let body = request.httpBody {
            requestLogMessage = requestLogMessage + "\nBody:\n"
            if let json = try? JSONSerialization.jsonObject(with: body, options: []) {
                if let dict = json as? [String : Any] {
                    requestLogMessage = requestLogMessage + "\n\(dict)"
                } else {
                    requestLogMessage = requestLogMessage + "\n\t\(json)"
                }
            } else {
                requestLogMessage = requestLogMessage + "\n\t(body)"
                if let bodyRange = Range(NSMakeRange(0, min(1050, body.count))) {
                    let initialBodyData = body.subdata(in: bodyRange)
                    var buffer: [UInt8] = [UInt8](repeating: UInt8(0), count: initialBodyData.count)
                    initialBodyData.copyBytes(to: &buffer, count: buffer.count)
                    if let bodyString = String.init(bytes: buffer, encoding: .utf8) {
                        requestLogMessage = requestLogMessage + "\n\t\(bodyString)..."
                    }
                } else {
                    print("Unable to create range for data in request body")
                }
            }
        }
        requestLogMessage = requestLogMessage + "\n"
        print(requestLogMessage)
        session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if let data = data, let response = response as? HTTPURLResponse {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if 200...299 ~= response.statusCode {
                    print("request succeeded")
                    success(json as AnyObject?)
                    successWithData?(data)
                } else {
                    var serverInfo = "No details from server"
                    if let dict = json as? [String : AnyObject], dict["error_description"] != nil {
                        serverInfo = dict["error_description"] as! String
                        print("Error calling cloud.  Description \(response.description)\n   Payload: \(dict)")
                    } else {
                        print("Error calling cloud.  Description \(response.description)\n   Payload: \(String(describing: json))")
                    }
                    let responseError = identifyError(response.statusCode, details: serverInfo)
                    failure(responseError)
                }
            } else if let error = error {
                print("Error sending request: \(error)")
                failure(error as NSError)
            } else {
                print("Error sending request, but no data or error object to report")
                let responseError = identifyError(-1, details: "Error sending request")
                failure(responseError)
            }
        }).resume()
    }

    open func download(_ request: NSMutableURLRequest, progressUpdate: ((_ progress: Float) -> ())?, success: ((_ data: URL) -> ())?, failure: ((_ error: NSError) -> ())?) {
        request.httpMethod = HttpMethod.Get.rawValue
        let config = URLSessionConfiguration.default
        let downloadDelegate = DownloadDelegate()
        downloadDelegate.progressUpdate = progressUpdate
        downloadDelegate.success = success
        downloadDelegate.failure = failure

        let downloadSession = URLSession(configuration: config, delegate: downloadDelegate, delegateQueue: nil)
        let task = downloadSession.downloadTask(with: request as URLRequest)
        task.resume()
    }

    open func upload(_ request: NSMutableURLRequest, data: Data, contentType: ContentType, progressUpdate: ((_ progress: Float) -> ())?, success: (() -> ())?, failure: ((_ error: NSError) -> ())?) {
        request.httpMethod = HttpMethod.Post.rawValue
        request.setValue("\(contentType.rawValue)", forHTTPHeaderField: "Content-Type")

        let config = URLSessionConfiguration.default
        let uploadDelegate = UploadDelegate()
        uploadDelegate.progressUpdate = progressUpdate
        uploadDelegate.success = success
        uploadDelegate.failure = failure

        let uploadSession = URLSession(configuration: config, delegate: uploadDelegate, delegateQueue: nil)
        let task = uploadSession.uploadTask(with: request as URLRequest, from: data)
        task.resume()
    }

    open func post(_ request: NSMutableURLRequest, success: @escaping (_ object: AnyObject?) -> (), failure: @escaping (_ error: NSError) -> ()) {
        self.sendRequest(request, method: .Post, success: success, failure: failure)
    }

    open func put(_ request: NSMutableURLRequest, success: @escaping (_ object: AnyObject?) -> (), failure: @escaping (_ error: NSError) -> ()) {
        self.sendRequest(request, method: .Put, success: success, failure: failure)
    }
    
    open func delete(_ request: NSMutableURLRequest, success: @escaping (_ object: AnyObject?) -> (), failure: @escaping (_ error: NSError) -> ()) {
        self.sendRequest(request, method: .Delete, success: success, failure: failure)
    }

    open func get(_ request: NSMutableURLRequest,
                  success: @escaping (_ object: AnyObject?) -> (),
                  failure: @escaping (_ error: NSError) -> (),
                  successWithData: ((_ data: Data) -> ())? = nil) {
        self.sendRequest(request, method: .Get, success: success, failure: failure, successWithData: successWithData)
    }

    open func clientURLRequest(_ url: String, params: Dictionary<String, AnyObject>? = nil) -> NSMutableURLRequest {
        let url = URL(string: url)!
        let request = NSMutableURLRequest(url: url)
        request.addValue(ContentType.JSON.rawValue, forHTTPHeaderField: "Accept")

        if let params = params {
            request.setValue(ContentType.JSON.rawValue, forHTTPHeaderField: "Content-Type")
            let json = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
            request.httpBody = json
        }

        if let token = self.token {
            request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func clientURLMultipartRequest(_ requestUrl: URL, params: Dictionary<String, AnyObject>, fileUrl: URL) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: requestUrl)
        let boundary = "Boundary-\(NSUUID().uuidString)"

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = NSMutableData()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition:form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
//        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        if let json = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) {
            body.append(json)
        } else {
            print("Unable to convert params to JSON for multipart request")
        }
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        let filename = fileUrl.lastPathComponent
        body.append("Content-Disposition:form-data; name=\"asset\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)

        do {
            let fileData = try Data(contentsOf: fileUrl)
            body.append(fileData)
        } catch {
            print("Unable to load data from \(fileUrl.absoluteString) for upload")
        }

        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body as Data
        return request
    }

}
