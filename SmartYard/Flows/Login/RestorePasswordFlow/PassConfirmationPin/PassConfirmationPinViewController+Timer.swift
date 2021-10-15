//
//  PassConfirmationPinViewController+Timer.swift
//  SmartYard
//
//  Created by Mad Brains on 23.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

extension PassConfirmationPinViewController {
    
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
            sendCodeAgainMessageView.isHidden.toggle()
            timerLabel.text = "00:00"
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

        timerLabel.text = String(format: "%02d:%02d", components.minute ?? 0, components.second ?? 0)
    }
    
}
