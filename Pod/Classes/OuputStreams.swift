//
//  Streams.swift
//  Pods
//
//  Created by Michael Seemann on 18.10.15.
//
//


import Foundation

/**
 Replacement for NSOutputStream. What's wrong with NSOutputStream? It is an abstract class by definition - but i think 
 it should be a protocol. So we can easily create different implementations like MemOutputStream or FileOutputStream and add
 Buffer mechanisms.
*/
protocol HKOutputStream {
    var outputStream: OutputStream { get }
    func open()
    func close()
    func isOpen() -> Bool
    func write(theString: String)
    func getDataAsString() -> String
}

/**
    Abtract Class implementation of the outputstream
*/
extension HKOutputStream {
    
    private func write(buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return self.outputStream.write(buffer, maxLength: len)
    }
    
    private func stringToData(theString: String) -> NSData {
        return theString.data(using: String.Encoding.utf8)! as NSData
    }
    
    func write(theString: String) {
        let data = stringToData(theString: theString) as Data
        _ = data.withUnsafeBytes {
            self.outputStream.write($0, maxLength: data.count)
        }
        
    }
    
    func open(){
        outputStream.open()
    }
    
    func close() {
        outputStream.close()
    }
    
    func isOpen() -> Bool {
        return outputStream.streamStatus == Stream.Status.open
    }
}

/**
    A memory output stream. Caution: the resulting json string must fit in the device mem!
*/
internal class MemOutputStream : HKOutputStream {
    
    var outputStream: OutputStream
    
    init(){
        self.outputStream = OutputStream.toMemory()
    }
    
    func getDataAsString() -> String {
        close()
        let data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey)
        
        return NSString(data: (data as! NSData) as Data, encoding: String.Encoding.utf8.rawValue)! as String
    }
}

/**
    A file output stream. The stream will overwrite any existing file content.
*/
internal class FileOutputStream : HKOutputStream {
    var outputStream: OutputStream
    var fileAtPath: String
    
    init(fileAtPath: String){
        self.fileAtPath = fileAtPath
        self.outputStream = OutputStream(toFileAtPath: fileAtPath, append: false)!
    }
    
    func getDataAsString() -> String {
        close()
        return try! NSString(contentsOfFile: fileAtPath, encoding: String.Encoding.utf8.rawValue) as String
    }
}
