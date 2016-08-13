// ResponseSerializer.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

public struct ResponseSerializer: S4.ResponseSerializer {
    
    let transport: Stream
    
    public init(stream: Stream) {
        self.transport = stream
    }

    public func serialize(_ response: Response) throws {
        let newLine: Data = [13, 10]

        try transport.send("HTTP/\(response.version.major).\(response.version.minor) \(response.status.statusCode) \(response.status.reasonPhrase)".data)
        try transport.send(newLine)

        for (name, value) in response.headers.headers {
            try transport.send("\(name): \(value)".data)
            try transport.send(newLine)
        }

        for cookie in response.cookieHeaders {
            try transport.send("Set-Cookie: \(cookie)".data)
            try transport.send(newLine)
        }

        try transport.send(newLine)

        switch response.body {
        case .buffer(let buffer):
            try transport.send(buffer)
        case .receiver(let receiver):
            while !receiver.closed {
                let data = try receiver.receive(upTo: 2014)
                guard data.count > 0 else {
                    break
                }
                try transport.send(String(data.count, radix: 16).data)
                try transport.send(newLine)
                try transport.send(data)
                try transport.send(newLine)
            }

            try transport.send("0".data)
            try transport.send(newLine)
            try transport.send(newLine)
        case .sender(let sender):
            let body = BodyStream(transport)
            try sender(body)

            try transport.send("0".data)
            try transport.send(newLine)
            try transport.send(newLine)
        default:
            throw BodyError.inconvertibleType
        }

        try transport.flush()
    }
}
