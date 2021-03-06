//
//  VideoBlockViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 3/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@testable import edX

class VideoBlockViewControllerTests : SnapshotTestCase {

    func testSnapshotYoutubeOnly() {
        // Create a course with a youtube video
        let summary = OEXVideoSummary(videoID: "some-video", name: "Youtube Video", encodings: [
            "youtube": OEXVideoEncoding(name: "youtube", url: "https://some-youtube-url", size: 12)])
        let outline = CourseOutline(root: "root", blocks: [
            "root" : CourseBlock(type: CourseBlockType.course, children: ["video"], blockID: "root", name: "Root", multiDevice: true, graded: false),
            "video" : CourseBlock(type: CourseBlockType.video(summary), children: [], blockID: "video", name: "Youtube Video", blockURL: URL(string: "www.example.com"), multiDevice: true, graded: false)
            ])

        let environment = TestRouterEnvironment()
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: "some-course", outline: outline)

        let videoController = VideoBlockViewController(environment: environment, blockID: "video", courseID: "some-course")
        inScreenNavigationContext(videoController) {
            assertSnapshotValidWithContent(videoController.navigationController!)
        }
    }
}
