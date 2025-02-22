//
//  AppDelegate.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 17/02/2025.
//

import UIKit
import SwiftyBluetooth
import CoreBluetooth

let serviceID = "0003abcd-0000-1000-8000-00805F9B34FB"
let characteristicID = "FFE1"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var saveDevice: Peripheral!
    var devices = [Peripheral]()
    var bleTimer = Timer()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SwiftyBluetooth.setSharedCentralInstanceWith(restoreIdentifier: "SwiftyBluetooth")
        UIApplication.shared.isIdleTimerDisabled = true
        bleTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(searchBLEDevices), userInfo: nil, repeats: true)
        bleTimer.fire()
        return true
    }
    
    //MARK: - Search BLE Devices
    @objc func searchBLEDevices() {
        let saveDeviceIdentifier = UserDefaults.standard.string(forKey: "DeviceName")
        if(saveDevice != nil){
            
            if(saveDevice.state == .connected){
                print("connected",saveDevice.state)
            } else {
                print("not connected",saveDevice.state)
                saveDevice.connect(withTimeout: .infinity, completion: {(result) in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        break
                    }
                })
            }
            
        } else if saveDevice == nil && saveDeviceIdentifier != nil {
            SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: [CBUUID(string: serviceID)], options: nil, timeoutAfter: 10, completion: {(scanResult) in
                switch scanResult {
                    
                case .scanStarted:
                    print("Scan for devices has been called")
                case .scanResult(peripheral: let peripheral, advertisementData: let advertisementData, RSSI: let RSSI):
                    print("Scanning has a result")
                    if peripheral.identifier == UUID(uuidString: saveDeviceIdentifier!) {
                        SwiftyBluetooth.stopScan()
                        self.saveDevice = peripheral
                        self.saveDevice.connect(withTimeout: .infinity, completion: {(result) in
                            print(peripheral.name)
                            switch result {
                            case .success:
                                break
                            case .failure(let error):
                                break
                            }
                        })
                    }
                case .scanStopped(peripherals: let peripherals, error: let error):
                    print("Scanning has been stopped")
                }
            })
        }
    }
    
    func sendCommand(command: String){
        print(command)
        if(saveDevice != nil && saveDevice.state == .connected){
            saveDevice.writeValue(ofCharacWithUUID: characteristicID,fromServiceWithUUID: serviceID, value: command.data(using: .ascii)!,completion: { result in
                switch result {
                case .success():
                    print("sent succesfully")
                case .failure(let err):
                    print(err.localizedDescription)
                }
                
            })
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if(saveDevice != nil) {
            print("entering background")
            saveDevice.disconnect { (error) in
                do {
                    try print(error.get())
                } catch {
                    print(error.localizedDescription)
                }
                self.saveDevice = nil
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if(saveDevice != nil){
            saveDevice.disconnect { (error) in
                do {
                    try print(error.get())
                } catch {
                    print(error.localizedDescription)
                }
                self.saveDevice = nil
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(searchBLEDevices), userInfo: nil, repeats: false)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

