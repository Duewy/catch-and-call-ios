//
//  MapQueryFilters.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-15.
//
//
//  1:1 with Android MapQueryFilters so logic stays in sync.

import Foundation

struct MapQueryFilters {
    var dateRange: String          // "2025-02-01 to 2025-02-28"
    var species: String            // "All", "Largemouth", etc.
    var eventType: String          // "Fun Day", "Tournament", "Both"
    var sizeType: String           // "Weight" or "Length"
    var sizeRange: String          // "1.0 - 5.5"
    var measurementType: String    // "Imperial (lbs/oz, inches)" or "Metric (kg, cm)"

    static var `default`: MapQueryFilters {
        MapQueryFilters(
            dateRange: "All",
            species: "All",
            eventType: "Both",
            sizeType: "Weight",
            sizeRange: "0 - 9999",
            measurementType: "Imperial (lbs/oz, inches)"
        )
    }
}

