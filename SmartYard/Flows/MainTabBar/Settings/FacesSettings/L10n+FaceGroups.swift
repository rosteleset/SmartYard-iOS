//
//  Created by Александр Попов on 03.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

extension L10n.Settings.Faces {
    enum Groups {
        static let title = L10n.tr("settings.faces.groups.title")
        static let helpTitle = L10n.tr("settings.faces.groups.helpTitle")
        static let faceActions = L10n.tr("settings.faces.groups.faceActions")
        static let clusterHint = L10n.tr("settings.faces.groups.clusterHint")
        static let screenTitle = L10n.tr("settings.faces.groups.screenTitle")

        static let all = L10n.tr("settings.faces.groups.all")
        static let ungrouped = L10n.tr("settings.faces.groups.ungrouped")
        static let add = L10n.tr("settings.faces.groups.add")
        static let edit = L10n.tr("settings.faces.groups.edit")
        static let delete = L10n.tr("settings.faces.groups.delete")

        static func deleteConfirmation(_ name: String) -> String {
            String(format: L10n.tr("settings.faces.groups.deleteConfirmation"), name)
        }

        static let actions = L10n.tr("settings.faces.groups.actions")
        static let cluster = L10n.tr("settings.faces.groups.cluster")
        static let prefix = L10n.tr("settings.faces.groups.prefix")
        static let name = L10n.tr("settings.faces.groups.name")
        static let track = L10n.tr("settings.faces.groups.track")
        static let move = L10n.tr("settings.faces.groups.move")
        static let detach = L10n.tr("settings.faces.groups.detach")
        static let retry = L10n.tr("settings.faces.groups.retry")
    }
}
