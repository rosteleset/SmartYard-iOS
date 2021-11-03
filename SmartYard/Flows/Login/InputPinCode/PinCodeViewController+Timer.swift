//
//  PinCodeViewController+Timer.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

extension PinCodeViewController {
    
    func runCodeTimer() {
        timeEnd = Date(timeInterval: 60, since: Date())
        updateTimer()
        
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(self.updateTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func updateTimer() {
        guard let timeEnd = timeEnd else {
            return
        }
        
        let timeNow = Date()
        
        guard timeEnd.compare(timeNow) == ComparisonResult.orderedDescending else {
            sendCodeAgainButton.isHidden.toggle()
            sendCodeAgainLabelView.isHidden.toggle()
            updateTimeValues(minutesValue: 0, secondsValue: 0)
            timer?.invalidate()
            timer = nil
            
            return
        }
        
        let calendar = NSCalendar.current
        
        let components = calendar.dateComponents(
            [.minute, .second],
            from: timeNow,
            to: timeEnd
        )
        
        updateTimeValues(minutesValue: components.minute, secondsValue: components.second)
    }
    
    func updateTimeValues(minutesValue: Int?, secondsValue: Int?) {
        guard let minutes = minutesValue, let seconds = secondsValue else {
            timerLabel.text = "00:00"
            return
        }
        
        let min = String(minutes)
        let sec = String(seconds)
        
        let minutesText = min.count == 1 ? "0" + min : min
        let secondesText = sec.count == 1 ? "0" + sec : sec
        timerLabel.text = minutesText + ":" + secondesText
    }
    
}
