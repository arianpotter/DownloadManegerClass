//
//  DownloadTask.swift
//  demo
//
//  Created by Arian Hadi on 3/4/20.
//  Copyright © 2020 Arian Hadi. All rights reserved.
//

import Foundation
import CoreFoundation
import UIKit
struct DownloadTaskProperty{
    var totalBytes:Int64 = 0
    var urlRequest:URLRequest
    var Range:String = ""
    var Id:Int = 0
}
class DownloadManager:NSObject,URLSessionDownloadDelegate,URLSessionDataDelegate{
    
    
    //MARK: - Properties
    
    
    private var partsCompleted:Int = 0
    let downloadURL:URL
    var fileName:String = ""
    var fileSize:Int64 = 0
    var totalSpeed:Int64 = 0
    private var tempLocations = [URL]()
    lazy var time:CFAbsoluteTime={
        return CFAbsoluteTimeGetCurrent()
    }()
    var numberOfConnections : Int = 1
    private var downloadTasks = [URLSessionDownloadTask:DownloadTaskProperty]()
    var downloadSpeed:UILabel
    var downloadSpeedUnit:UILabel
    var downloadViewController:UIViewController
    var downloadProgress:UIProgressView
    private lazy var urlSession : URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
   //MARK: - Initialization
    init(downloadAddress:URL,segments:Int,downloadSpeedLabel:UILabel,downloadUnitLabel:UILabel,dedicatedViewController:UIViewController,progress:UIProgressView){
        downloadURL=downloadAddress
        downloadSpeed=downloadSpeedLabel
        downloadSpeedUnit=downloadUnitLabel
        downloadViewController=dedicatedViewController
        downloadProgress=progress
        numberOfConnections=segments
        super.init()
    }
    
    //MARK: - Data response to HEAD function
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void){
                        let httpresp = response as! HTTPURLResponse
                        self.fileName = (response.suggestedFilename)!
                        self.fileSize = Int64(httpresp.value(forHTTPHeaderField: "Content-Length")!)!
                        if(httpresp.value(forHTTPHeaderField: "Accept-Ranges") == "bytes"){
                            let tempUrl = URL(string:"some")
                            for _ in 0..<numberOfConnections{
                                tempLocations.append(tempUrl!)
                            }
                            let eachSection = Int64(self.fileSize/Int64(numberOfConnections))
                            var total:Int64 = 0
                            for i in 0..<numberOfConnections {
                                let tempReq = URLRequest(url: self.downloadURL)
                                var tempTaskProp = DownloadTaskProperty(urlRequest: tempReq)
                                tempTaskProp.Id = i
                                if(i == numberOfConnections-1){
                                    tempTaskProp.Range = "bytes="+String(total)+"-"+String(self.fileSize-1)
                                }
                                else{
                                    tempTaskProp.Range = "bytes="+String(total)+"-"+String(total+eachSection)
                                    total += eachSection
                                    total += 1
                                }
                                tempTaskProp.urlRequest.setValue(tempTaskProp.Range, forHTTPHeaderField: "Range")
                                let tempTask = self.urlSession.downloadTask(with: tempTaskProp.urlRequest)
                                self.downloadTasks[tempTask] = tempTaskProp
                            }
                        }
                        else{
                            numberOfConnections = 1
                            let tempReq = URLRequest(url: self.downloadURL)
                            let tempTaskProp = DownloadTaskProperty(urlRequest: tempReq)
                            let tempTask = self.urlSession.downloadTask(with: tempTaskProp.urlRequest)
                            self.downloadTasks[tempTask] = tempTaskProp
                        }
        completionHandler(.cancel)
        
        
        //main downloades start here
        for task in downloadTasks.keys {
            task.resume()
        }
}
    //MARK: - Starting download function
    
    func startDownload() {
        //check wether server capable of multiconnection or not
        var tempReq = URLRequest(url: downloadURL)
        tempReq.httpMethod = "HEAD"
        let tempData = urlSession.dataTask(with: tempReq)
        tempData.resume()
    }
    
    //MARK: - Download progress tracking function
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if(Int(CFAbsoluteTimeGetCurrent()-time)==1){
            totalSpeed += bytesWritten - downloadTasks[downloadTask]!.totalBytes
            DispatchQueue.main.async {
                if(self.totalSpeed/1000>1000){
                    self.downloadSpeedUnit.text="MB/s"
                    self.downloadSpeed.text=String(Double(self.totalSpeed/1000000))
                }
                else{
                    self.downloadSpeedUnit.text="KB/s"
                    self.downloadSpeed.text=String(self.totalSpeed/1000)
                }
                self.downloadProgress.progress = Float(self.totalSpeed/self.fileSize)
            }
            time = CFAbsoluteTimeGetCurrent()
            downloadTasks[downloadTask]?.totalBytes = totalBytesWritten
            totalSpeed = 0
        }
    }
    
    
    //MARK: - DownloadTask finishing function
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let temp = documentsURL.appendingPathComponent(location.lastPathComponent)
           try FileManager.default.moveItem(at: location, to: temp)
            tempLocations[(downloadTasks[downloadTask]?.Id)!]=temp

        } catch {
            print(error)
        }
        partsCompleted += 1
        if(partsCompleted==numberOfConnections){
            merge()
        }
    }
    
    //MARK: - Merging function
    
    
    private func merge(){
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let final = documentsURL.appendingPathComponent(fileName)
            FileManager.default.createFile(atPath: final.path, contents: nil, attributes: nil)
            let writer = try FileHandle(forWritingTo: final)
            
            
            for i in 0..<numberOfConnections{
                let reader = try FileHandle(forReadingFrom: tempLocations[i])
                let data = reader.readDataToEndOfFile()
                writer.write(data)
                reader.closeFile()
                try FileManager.default.removeItem(at: tempLocations[i])
            }
            writer.closeFile()
            let alert = UIAlertController(title: "Hoora", message: "Download Completed Bitch!", preferredStyle: .alert)
            DispatchQueue.main.async {
                self.downloadViewController.present(alert, animated: true, completion: nil)
            }
        } catch {
            print(error)
        }
    }
}
