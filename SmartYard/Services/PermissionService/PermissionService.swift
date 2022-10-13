//
//  PermissionService.swift
//  SmartYard
//
//  Created by admin on 25/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift
import AVFoundation
import Contacts

class PermissionService {
    
    func hasAccess(to mediaType: AVMediaType) -> Single<Void?> {
        return Single.create(
            subscribe: { single in
                AVCaptureDevice.requestAccess(for: mediaType) { isPermissionGranted in
                    guard isPermissionGranted else {
                        single(.failure(NSError.PermissionError.noCameraPermission))
                        return
                    }
                    
                    single(.success(()))
                }
                
                return Disposables.create()
            }
        )
    }
    
    func contactsAccessStatus() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestAccessToContacts() -> Single<Void?> {
        return Single.create(
            subscribe: { single in
                CNContactStore().requestAccess(for: .contacts) { isPermissionGranted, error in
                    guard isPermissionGranted else {
                        single(.failure(error ?? NSError.PermissionError.noContactsPermission))
                        return
                    }
                    
                    single(.success(()))
                }
                
                return Disposables.create()
            }
        )
    }
    
    func requestAccessToMic() -> Single<Void?> {
        return Single.create(
            subscribe: { single in
                AVAudioSession.sharedInstance().requestRecordPermission { isPermissionGranted in
                    guard isPermissionGranted else {
                        single(.failure(NSError.PermissionError.noMicPermission))
                        return
                    }
                    
                    single(.success(()))
                }
                
                return Disposables.create()
            }
        )
    }
    
}
