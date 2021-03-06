//
//  HealthkitProfile.swift
//  Pods
//
//  Created by Michael Seemann on 23.10.15.
//
//

import Foundation
import HealthKit
///MetaData of a profile
public class HealthKitProfileMetaData {
    /// the name of the profile
    internal(set) public var profileName: String?
    /// the date the profie was exported
    internal(set) public var creationDate: NSDate?
    /// the version of the profile
    internal(set) public var version: String?
    /// the type of the profile
    internal(set) public var type: String?
}

/// a healthkit Profile - can be used to read data from the profile and import the profile into the healthkit store.
public class HealthKitProfile : CustomStringConvertible {
    
    let fileAtPath: NSURL
    /// the name of the profile file - without any path components
    private(set) public var fileName: String
    /// the size of the profile file in bytes
    private(set) public var fileSize:UInt64?
    
    let fileReadQueue = OperationQueue()

    /// for textual representation of this object
    public var description: String {
        return "\(fileName) \(String(describing: fileSize))"
    }
    
    /**
        constructor for aprofile
        - Parameter fileAtPath: the Url of the profile in the file system
    */
    public init(fileAtPath: NSURL){
        fileReadQueue.maxConcurrentOperationCount = 1
        fileReadQueue.qualityOfService = QualityOfService.userInteractive
        self.fileAtPath = fileAtPath
        self.fileName   = self.fileAtPath.lastPathComponent!
        let attr:NSDictionary? = try! FileManager.default.attributesOfItem(atPath: fileAtPath.path!) as NSDictionary
        if let _attr = attr {
            self.fileSize = _attr.fileSize();
        }
    }
    
    /**file:///Users/scott.jenkins/Library/Developer/CoreSimulator/Devices/536CB186-552B-4DCD-8C6B-DD18F7A182F4/data/Containers/Data/Application/E398B4DE-5248-4C84-89FD-56159074B5E4/Documents/
     Load the MetaData of a profile. If the metadata have been readed the reading is 
     interrupted - by this way also very large files are supported to.
     - Returns: the HealthKitProfileMetaData that were read from the profile.
    */
    internal func loadMetaData() -> HealthKitProfileMetaData {
        let result          = HealthKitProfileMetaData()
        let metaDataOutput  = MetaDataOutputJsonHandler()
        
        JsonReader.readFileAtPath(fileAtPath: self.fileAtPath.path!, withJsonHandler: metaDataOutput)
        
        let metaData = metaDataOutput.getMetaData()
        
        if let dateTime = metaData["creationDate"] as? NSNumber {
            result.creationDate = NSDate(timeIntervalSince1970: dateTime.doubleValue/1000)
        }
        
        result.profileName  = metaData["profileName"] as? String
        result.version      = metaData["version"] as? String
        result.type         = metaData["type"] as? String
        
        return result
    }
    
    /**
     Load the MetaData of a profile. If the metadata have been readed the reading is
     interrupted - by this way also very large files are supported to.
     - Parameter asynchronous: if true the metsdata wil be read asynchronously. If false the read will be synchronous.
     - Parameter callback: is called if the meatdat have been read.
    */
    public func loadMetaData(asynchronous:Bool, callback:@escaping (_ metaData: HealthKitProfileMetaData) -> Void ){
        
        if asynchronous {
            fileReadQueue.addOperation(){
                callback(self.loadMetaData())
            }
        } else {
            callback(loadMetaData())
        }
    }
    
    /**
        Reads all samples from the profile and fires the callback onSample on every sample.
        - Parameter onSample: the callback is called on every sample.
    */
    func importSamples(onSample: @escaping (_ sample: HKSample) -> Void) throws {
        
        let sampleImportHandler = SampleOutputJsonHandler(){
            (sampleDict:AnyObject, typeName: String) in

            if let creator = SampleCreatorRegistry.get(typeName: typeName) {
                let sampleOpt:HKSample? = creator.createSample(sampleDict: sampleDict)
                if let sample = sampleOpt {
                    onSample(sample)
                }
            }
        }
        
        JsonReader.readFileAtPath(fileAtPath: self.fileAtPath.path!, withJsonHandler: sampleImportHandler)
    }
    
    /**
        removes the profile from the file system
    */
    public func deleteFile() throws {
        try FileManager.default.removeItem(atPath: fileAtPath.path!)
    }
}
