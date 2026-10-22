//
//  FaceGroupsTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import XCTest

final class FaceGroupsTests: XCTestCase {
    func testFacesDecodeLegacyAndNumericIdentifiers() throws {
        let json = #"[{"faceId":"12","image":"a"},{"faceId":13,"image":"b","groupId":"7"}]"#
        let faces = try JSONDecoder().decode([APIFace].self, from: Data(json.utf8))
        XCTAssertEqual(faces, [.init(faceId: 12, image: "a"), .init(faceId: 13, image: "b", groupId: 7)])
    }

    func testNullAndZeroGroupsAreUngrouped() throws {
        for value in ["null", "0", "\"0\"", "-1"] {
            let json = "{\"faceId\":1,\"image\":\"a\",\"groupId\":\(value)}"
            let face = try JSONDecoder().decode(APIFace.self, from: Data(json.utf8))
            XCTAssertNil(face.groupId)
            XCTAssertTrue(FaceGroupFilter.ungrouped.includes(face))
        }
    }

    func testGroupsDecodeStringIdentifiersAndAbsentWatcher() throws {
        let json =
            #"[{"groupId":"4","groupName":"Family","watcherId":"8"},{"groupId":5,"groupName":"Guests","watcherId":0}]"#
        let groups = try JSONDecoder().decode([APIFaceGroup].self, from: Data(json.utf8))
        XCTAssertEqual(groups[0], .init(groupId: 4, groupName: "Family", watcherId: 8))
        XCTAssertNil(groups[1].watcherId)
    }

    func testInvalidCreatedGroupCannotBeAssigned() {
        for json in [#"{"groupId":0}"#, #"{"groupId":"invalid"}"#, #"{}"#] {
            XCTAssertThrowsError(try JSONDecoder().decode(AddFaceGroupResponse.self, from: Data(json.utf8)))
        }
    }

    func testLikeResponseSupportsOldAndNewServers() throws {
        XCTAssertNil(try JSONDecoder().decode(LikeFaceResponse.self, from: Data("{}".utf8)).faceId)
        let json = #"{"faceId":"19"}"#
        XCTAssertEqual(try JSONDecoder().decode(LikeFaceResponse.self, from: Data(json.utf8)).faceId, 19)
    }

    func testFiltersAndDeletedSelection() {
        let faces = [APIFace(faceId: 1, image: "a"), APIFace(faceId: 2, image: "b", groupId: 4)]
        XCTAssertEqual(faces.filter(FaceGroupFilter.all.includes).count, 2)
        XCTAssertEqual(faces.filter(FaceGroupFilter.ungrouped.includes).map(\.faceId), [1])
        XCTAssertEqual(faces.filter(FaceGroupFilter.group(4).includes).map(\.faceId), [2])
        XCTAssertEqual(FaceGroupFilter.group(4).resolved(in: []), .all)
        XCTAssertEqual(FaceGroupFilter.ungrouped.resolved(in: []), .ungrouped)
    }

    func testJournalUsesCurrentMembershipAndRenamedGroup() {
        let result = FaceGroupMetadata.resolve(
            faceId: 1,
            groupId: 4,
            groupName: "Old",
            faces: [.init(faceId: 1, image: "a", groupId: 5)],
            groups: [.init(groupId: 5, groupName: "Renamed")]
        )
        XCTAssertEqual(result, .init(groupId: 5, groupName: "Renamed"))
    }

    func testDeletedFaceOrGroupNoLongerOffersGroupTracking() {
        let deletedFace = FaceGroupMetadata.resolve(
            faceId: 1,
            groupId: 4,
            groupName: "Old",
            faces: [],
            groups: [.init(groupId: 4, groupName: "Group")]
        )
        let deletedGroup = FaceGroupMetadata.resolve(
            faceId: 1,
            groupId: 4,
            groupName: "Old",
            faces: [.init(faceId: 1, image: "a", groupId: 4)],
            groups: []
        )
        XCTAssertEqual(deletedFace, .init(groupId: nil, groupName: nil))
        XCTAssertEqual(deletedGroup, .init(groupId: nil, groupName: nil))
    }

    func testJournalKeepsServerMetadataUntilListsAreLoaded() {
        XCTAssertEqual(
            FaceGroupMetadata.resolve(faceId: 1, groupId: 4, groupName: "Family", faces: nil, groups: nil),
            .init(groupId: 4, groupName: "Family")
        )
    }

    func testRequestsMatchServerContracts() {
        struct RequestCase {
            let operation: FaceGroupRequest.Operation
            let path: String
            let parameters: [String: Any]

            init(_ operation: FaceGroupRequest.Operation, _ path: String, _ parameters: [String: Any]) {
                self.operation = operation
                self.path = path
                self.parameters = parameters
            }
        }
        let cases: [RequestCase] = [
            RequestCase(.list(flatId: 9), "user/listGroups", ["flatId": 9]),
            RequestCase(.create(flatId: 9, name: "Family"), "user/addGroup", ["flatId": 9, "groupName": "Family"]),
            RequestCase(
                .rename(flatId: 9, groupId: 4, name: "New"),
                "user/updateGroup",
                ["flatId": 9, "groupId": 4, "groupName": "New"]
            ),
            RequestCase(.delete(flatId: 9, groupId: 4), "user/deleteGroup", ["flatId": 9, "groupId": 4]),
            RequestCase(.attach(faceId: 1, groupId: 4), "frs/attachFaceToGroup", ["faceId": 1, "groupId": 4]),
            RequestCase(.detach(faceId: 1, groupId: 4), "frs/detachFaceFromGroup", ["faceId": 1, "groupId": 4]),
            RequestCase(.cluster(flatId: 9, prefix: "Group"), "frs/clusterFaces", ["flatId": 9, "prefixName": "Group"])
        ]
        for item in cases {
            let request = FaceGroupRequest(accessToken: "test", operation: item.operation)
            XCTAssertEqual(request.path, item.path)
            XCTAssertEqual(request.requestParameters as NSDictionary, item.parameters as NSDictionary)
        }
    }

    func testListFacesOmitsUngroupedSentinelAndSupportsServerGroupFilter() {
        let all = GetPersonFacesRequest(accessToken: "test", forceRefresh: true, flatId: 9)
        let selected = GetPersonFacesRequest(accessToken: "test", forceRefresh: true, flatId: 9, groupId: 4)
        let ungrouped = GetPersonFacesRequest(accessToken: "test", forceRefresh: true, flatId: 9, groupId: -1)
        XCTAssertNil(all.requestParameters["groupId"])
        XCTAssertNil(ungrouped.requestParameters["groupId"])
        XCTAssertEqual(selected.requestParameters["groupId"] as? Int, 4)
    }
}
