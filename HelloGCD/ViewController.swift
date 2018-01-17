//
//  ViewController.swift
//  HelloGCD
//
//  Created by Hari Krishna Bista on 1/16/18.
//  Copyright © 2018 meroapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    static let HISTOGRAM_SIZE = 20
    static let IMAGE_SIZE = 1000
    
    // initialize the image with IMAGE_SIZE*IMAGE_SIZE
    static var image:[[Int]] = [[Int]](repeating: [Int](repeating: -1, count: ViewController.IMAGE_SIZE), count: ViewController.IMAGE_SIZE)
    
    // initialize the result of histogram with 0 to HISTOGRAM_SIZE
    static var result:[Int] = Array<Int>(repeating: 0, count: ViewController.HISTOGRAM_SIZE)
    static var NUM_OF_PROCESSOR = 8
    static var semaphore = DispatchSemaphore(value: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lower : UInt32 = 0
        let upper : UInt32 = UInt32(ViewController.HISTOGRAM_SIZE)
        
        // create an image with random values from 0 to 9
        for (i,row) in ViewController.image.enumerated() {
            print("inittialization row: \(i)")
            for (j,_) in row.enumerated() {
                ViewController.image[i][j] = Int(arc4random_uniform(upper - lower) + lower)
            }
        }
        
        self.runGCDParallel()
//      self.runSequential()
    }
    
    func runSequential() {
        
        let sTime = Date()
        
        for (i,row) in ViewController.image.enumerated() {
            print("row: \(i)")
            for item in row{
                
                // increasing amount of sequential work to do other wise it is too much engaging in lock operation which does not truly reflects the benefit of multi-threading
                var val = 0
                for i in 0...1000 {
                    val = val + i
                }
                
                ViewController.result[item] = ViewController.result[item] + 1
            }
        }
        
        let elapsed = Date().timeIntervalSince(sTime)
        let truncatedElapsed = String(format: "%.12f", elapsed)
        print("time taken to calculate Histogram: \(truncatedElapsed)")
        
        print("result:")
        print(ViewController.result)
        
        let sum = ViewController.result.reduce(0) { (x, y) -> Int in
            x + y
        }
        
        print("sum: \(sum)")
    }
    
    // using GCD
    func runGCDParallel() {
        
        let sTime = Date()
        
        // create semaphores with the size of HISTOGRAM_SIZE to reduce collision
        var semaphones:Array<DispatchSemaphore> = []

        let grouping = (ViewController.IMAGE_SIZE - 1)/ViewController.NUM_OF_PROCESSOR + 1
        
        let queue = DispatchQueue(label: "com.meroapp.queue", attributes: .concurrent)
        var workItems:[DispatchWorkItem] = []
        
        for _ in 0...(ViewController.HISTOGRAM_SIZE - 1) {
            semaphones.append(DispatchSemaphore(value: 1))
        }
        
        for i in 0...(ViewController.NUM_OF_PROCESSOR - 1) {
            
            let sIndex = i * grouping
            var eIndex = (i + 1) * grouping - 1
            
            if(eIndex > ViewController.IMAGE_SIZE - 1){
                eIndex = ViewController.IMAGE_SIZE - 1
            }
            
            let workItem = DispatchWorkItem(block: {
                print("parallel processing on sIndex: \(sIndex) eIndex: \(eIndex)")
                
                for i in sIndex...eIndex {
                    let row = ViewController.image[i]
                    for item in row {
                        
                        // increasing amount of sequential work to do other wise it is too much engaging in lock operation which does not truly reflects the benefit of multi-threading
                        var val = 0
                        for i in 0...1000 {
                            val = val + i
                        }
                        
                        semaphones[item].wait()
                        ViewController.result[item] = ViewController.result[item] + 1
                        semaphones[item].signal()
                    }
                }
                
                print("end of operation: \(i)")
            })
            
            workItems.append(workItem)
            queue.async(execute: workItem)
        }
        
        for workitem in workItems{
            workitem.wait()
        }
        
        print("wait over")
        
        let elapsed = Date().timeIntervalSince(sTime)
        let truncatedElapsed = String(format: "%.12f", elapsed)
        print("time taken to calculate Histogram: \(truncatedElapsed)")
        
        print("result:")
        print(ViewController.result)
        
        let sum = ViewController.result.reduce(0) { (x, y) -> Int in
            x + y
        }
        
        print("sum: \(sum)")
    }
    
//    // using OperationQueue
//    func runParallel() {
//        
//        //        var start = 0
//        //        let end = ViewController.IMAGE_SIZE
//        
//        let queue = OperationQueue()
//        queue.qualityOfService = .userInitiated
//        
//        // create semaphores with the size of HISTOGRAM_SIZE to reduce collision
//        var semaphones:Array<DispatchSemaphore> = []
//        
//        for _ in 0...(ViewController.HISTOGRAM_SIZE - 1) {
//            semaphones.append(DispatchSemaphore(value: 1))
//        }
//        
//        let grouping = (ViewController.IMAGE_SIZE - 1)/ViewController.NUM_OF_PROCESSOR + 1
//        
//        let sTime = Date()
//        
//        var arrOfBlockOperation:[BlockOperation] = []
//        
//        for i in 0...(ViewController.NUM_OF_PROCESSOR - 1) {
//            
//            let sIndex = i * grouping
//            var eIndex = (i + 1) * grouping - 1
//            
//            if(eIndex > ViewController.IMAGE_SIZE - 1){
//                eIndex = ViewController.IMAGE_SIZE - 1
//            }
//            
//            let aOperation = BlockOperation(block: {
//                
//                print("parallel processing on sIndex: \(sIndex) eIndex: \(eIndex)")
//                
//                for i in sIndex...eIndex {
//                    let row = ViewController.image[i]
//                    for item in row {
//                        
//                        var val = 0
//                        for i in 0...1000 {
//                            val = val + i
//                        }
//                        
//                        semaphones[item].wait()
//                        ViewController.result[item] = ViewController.result[item] + 1
//                        semaphones[item].signal()
//                    }
//                }
//                
//                print("end of operation: \(i)")
//            })
//            
//            arrOfBlockOperation.append(aOperation)
//            
//            //            queue.push
//        }
//        
//        queue.addOperations(arrOfBlockOperation, waitUntilFinished: true)
//        
//        //        queue.waitUntilAllOperationsAreFinished()
//        // when all the operations are completed print the result
//        
//        let elapsed = Date().timeIntervalSince(sTime)
//        let truncatedElapsed = String(format: "%.12f", elapsed)
//        print("time taken to calculate Histogram: \(truncatedElapsed)")
//        
//        print("result:")
//        print(ViewController.result)
//        
//        let sum = ViewController.result.reduce(0) { (x, y) -> Int in
//            x + y
//        }
//        
//        print("sum: \(sum)")
//    }
    
    func demoGCD() {
        let aWorkItem1 = DispatchWorkItem {
            print("work 1")
            
            var sum = 0
            for i in 0...10000000000 {
                sum = sum + i
            }
            
            print("end 1")
        }
        
        let aWorkItem2 = DispatchWorkItem {
            print("work 2")
            
            var sum = 0
            for i in 0...10000000000 {
                sum = sum + i
            }
            
            print("end 2")
        }
        
        let aWorkItem3 = DispatchWorkItem {
            print("work 3")
            
            var sum = 0
            for i in 0...10000000000 {
                sum = sum + i
            }
            
            print("end 3")
        }
        
        let aWorkItem4 = DispatchWorkItem {
            print("work 4")
            
            var sum = 0
            for i in 0...10000000000 {
                sum = sum + i
            }
            
            print("end 4")
        }
        
        let aWorkItem5 = DispatchWorkItem {
            print("work 5")
            
            var sum = 0
            for i in 0...10000000000 {
                sum = sum + i
            }
            
            print("end 5")
        }
        
        
        let queue = DispatchQueue(label: "queuename", attributes: .concurrent)
        
        queue.async(execute: aWorkItem1)
        queue.async(execute: aWorkItem2)
        queue.async(execute: aWorkItem3)
        queue.async(execute: aWorkItem4)
        queue.async(execute: aWorkItem5)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



