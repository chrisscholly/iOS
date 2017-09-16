//
//  SiteRatingScoreExtension.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import Foundation

public extension SiteRating {
    
    public var siteScore: Int {
        var score = 1
        score += httpsScore
        score += isMajorTrackerScore
        score += trackerCountScore
        score += containsMajorTrackerScore
        score += ipTrackerScore
        score += termsOfServiceScore
        
        let cache =  SiteRatingCache.shared
        if cache.add(domain: domain, score: score) {
            return score
        }
        return cache.get(domain: domain)!
    }
    
    private var httpsScore: Int {
        return https ? -1 : 0
    }
    
    private var trackerCountScore: Int {
        let baseScore = Double(totalTrackersDetected) / 10.0
        return Int(ceil(baseScore))
    }
    
    private var containsMajorTrackerScore: Int {
        return containsMajorTracker ? 1 : 0
    }
    
    private var isMajorTrackerScore: Int {
        guard let network = majorTrackingNetwork else { return 0 }
        let baseScore = Double(network.perentageOfPages) / 10.0
        return Int(ceil(baseScore))
    }
    
    private var ipTrackerScore: Int {
        return contrainsIpTracker ? 1 : 0
    }
    
    private var termsOfServiceScore: Int {
        guard let termsOfService = termsOfService else {
            return 0
        }
        switch termsOfService.classification {
        case TermsOfService.Classification.a: return -1
        case TermsOfService.Classification.b: return 0
        case TermsOfService.Classification.c: return 0
        case TermsOfService.Classification.d: return 1
        case TermsOfService.Classification.e: return 2
        }
    }
    
    public var siteGrade: SiteGrade {
        logCalculation()
        return SiteGrade.grade(fromScore: siteScore)
    }
    
    public func logCalculation() {
        Logger.log(text: "Site Score: { " +
            "host: \(url.host ?? ""), " +
            "https: \(https)-\(httpsScore), " +
            "isMajorTracker \(majorTrackingNetwork != nil)-\(isMajorTrackerScore), " +
            "trackersDetected: \(totalTrackersDetected)-\(trackerCountScore), " +
            "containsMajorTracker: \(containsMajorTracker)-\(containsMajorTrackerScore), " +
            "ipTracker: \(contrainsIpTracker)-\(ipTrackerScore), " +
            "tos: \(termsOfService?.classification.rawValue ?? "none")-\(termsOfServiceScore) }"
        )
    }
}

public class SiteRatingCache {
    
    public static let shared = SiteRatingCache()
    
    private var cachedScores = [String: Int]()
    
    /**
     Adds a score to the cache. Only replaces a preexisting score if
     the new score is higher
     - returns: true if the cache was updated, otherwise false
     */
    func add(domain: String, score: Int) -> Bool {
        return compareAndSet(domain: domain, score: score)
    }
    
    private func compareAndSet(domain: String, score current: Int) -> Bool {
        if let previous = cachedScores[domain], previous > current {
            return false
        }
        cachedScores[domain] = current
        return true
    }
    
    func get(domain: String) -> Int? {
        return cachedScores[domain]
    }
    
    func reset() {
        cachedScores =  [String: Int]()
    }
    
}
