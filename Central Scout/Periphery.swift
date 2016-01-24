//
//  BTRef.swift
//  Central Scout
//

import CoreBluetooth
import Cocoa

private var theData = NSMutableData()
private var fileCount = 0
extension AppDelegate: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service: CBService in peripheral.services as [CBService]! {
            LOG("Found service \(service)")
            if service.UUID.UUIDString == UUID_SERVICE.UUIDString {
                LOG("\tFinding characteristics of this service...")
                peripheral.discoverCharacteristics([UUID_CHARACTERISTIC], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for char in service.characteristics! {
            let aCharacteristic: CBCharacteristic = char as CBCharacteristic;
            if aCharacteristic.UUID.UUIDString == UUID_CHARACTERISTIC.UUIDString {
                LOG("Setting peripheral \(peripheral.name) to notify")
                peripheral.setNotifyValue(true, forCharacteristic: aCharacteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let data = characteristic.value
        LOG("Received \(data!.length) bytes of data")
        let error: NSError? = nil
        if error != nil {
            LOG("error discovering characteristic: \(error)")
            return
        }
        let stringFromData = NSString(data: data!, encoding: NSUTF8StringEncoding)
        if let str = stringFromData {
            if str.isEqualToString("EOM") {
                LOG("DONE- Data size = \(theData.length)")
                let finalData = theData as NSData
                do {
                    let dictionary = try NSJSONSerialization.JSONObjectWithData(finalData, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                    let filesDirectory = currentDirectory.stringValue
                    let name = NSUUID().UUIDString
                    let didWrite = dictionary!.writeToFile("\(filesDirectory)/\(name).plist", atomically: true)
                    LOG("did write = \(didWrite)")
                    self.lblReceivedFiles.stringValue = "\(++fileCount)"
                } catch {
                    LOG("problem turning data back into dictionary:: \(error)")
                }
                theData = NSMutableData()
            }  else {
                theData.appendData(data!)
            }
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic.isNotifying {
            LOG("IS NOTIFYING- \(peripheral.name)")
        } else {
            LOG("NOT NOTIFYING- \(peripheral.name)")
            self.manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        LOG("update write value for characteristic")
    }
}