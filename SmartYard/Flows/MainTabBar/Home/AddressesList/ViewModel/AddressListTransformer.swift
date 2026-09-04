//
//  AddressListTransformer.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation

enum AddressListTransformer {
    static func removingDuplicates<Element, Identifier: Hashable>(
        from elements: [Element],
        identifiedBy identifier: (Element) -> Identifier
    ) -> [Element] {
        var seenIdentifiers = Set<Identifier>()

        return elements.filter { element in
            seenIdentifiers.insert(identifier(element)).inserted
        }
    }

    static func sorted<Element, Identifier: Equatable>(
        _ elements: [Element],
        savedOrder: [Identifier],
        identifier: (Element) -> Identifier,
        title: (Element) -> String,
        hasDoors: (Element) -> Bool
    ) -> [Element] {
        guard !savedOrder.isEmpty else {
            let alphabetical = elements.sorted {
                title($0).localizedCaseInsensitiveCompare(title($1)) == .orderedAscending
            }
            let withDoors = alphabetical.filter(hasDoors)
            let withoutDoors = alphabetical.filter { !hasDoors($0) }

            return withDoors + withoutDoors
        }

        return elements.sorted { lhs, rhs in
            let lhsIndex = savedOrder.firstIndex(of: identifier(lhs)) ?? Int.max
            let rhsIndex = savedOrder.firstIndex(of: identifier(rhs)) ?? Int.max

            return lhsIndex != rhsIndex
                ? lhsIndex < rhsIndex
                : title(lhs).localizedCaseInsensitiveCompare(title(rhs)) == .orderedAscending
        }
    }
}
