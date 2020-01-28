//
//  LinphoneService.swift
//  sip lanta
//
//  Created by Antol Peshkov on 28/12/2019.
//  Copyright © 2019 Тарас Евченко. All rights reserved.
//

import Foundation
import linphonesw

class LinphoneService {
    
    static let shared = LinphoneService()
    
    private(set) var core: Core? = nil
    private var timer: Timer? = nil
    
    private init() {
    }
    
    func start() {
        do {
            let configName = "linphonerc_default"
            let factoryName = "linphonerc_factory"
            
            guard let configTarget = FileManager.default
                .urls(for: .libraryDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(configName) else {
                fatalError("Unable to write config file to library")
            }
            
            if let configSource = Bundle.main.url(forResource: configName, withExtension: ""),
                !FileManager.default.fileExists(atPath: configTarget.relativePath) {
                do {
                    try FileManager.default.copyItem(at: configSource, to: configTarget)
                } catch {
                    print("Unable to copy config file from bundle to library")
                }
            }

            core = try Factory.Instance.createCore(
                configPath: configTarget.relativePath,
                factoryConfigPath: Bundle.main.path(forResource: factoryName, ofType: "") ?? "",
                systemContext: nil
            )
            
            core?.avpfMode = .Enabled
            
            try core?.start()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                self.core?.iterate()
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        core?.stop()
        core = nil        
    }
    
}
