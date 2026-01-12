//
//  LocationService.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-10.
//

import Foundation
import CoreLocation

/// Power-saving, shared GPS service (one-shot style).
/// - Stays off by default
/// - On Save, requests a fresh (or recently cached) coordinate
/// - Shuts off immediately after getting a fix or on timeout

final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var completionQueue: [(CLLocationCoordinate2D?) -> Void] = []
    private var stopTimer: Timer?
    private var requestTimer: Timer?
    private var isUpdating = false

    /// Most recent location we’ve seen (may be stale)
    private(set) var lastFix: CLLocation?

    /// Maximum age for a cached fix to be considered “fresh”
    var defaultMaxAgeSeconds: TimeInterval = 30     //3 seconds to let user catch another before updating GPS location

    /// How long to run the radio (seconds) before giving up
    var defaultTimeoutSeconds: TimeInterval = 8

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50                         // coarse filter (saves power)
        manager.pausesLocationUpdatesAutomatically = true
        manager.allowsBackgroundLocationUpdates = false
    }

    // MARK: - Public setup
    func ensurePermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("⚠️ Location permission denied or restricted")
        default:
            break
        }
    }

    /// Synchronous accessor: returns a *fresh enough* cached coordinate if available.
    func freshCachedCoordinate(maxAge seconds: TimeInterval? = nil) -> CLLocationCoordinate2D? {
        guard let loc = lastFix else { return nil }
        let age = -loc.timestamp.timeIntervalSinceNow
        if age <= (seconds ?? defaultMaxAgeSeconds) {
            return loc.coordinate
        }
        return nil
    }

    /// One-shot request:
    /// - If a cached fresh fix exists, returns it immediately.
    /// - Otherwise, starts updates, waits up to `timeout`, returns best effort, and stops.
    func requestCoordinate(
        maxAge: TimeInterval? = nil,
        timeout: TimeInterval? = nil,
        completion: @escaping (CLLocationCoordinate2D?) -> Void
    ) {
        // If we have a fresh cached fix, return synchronously
        if let coord = freshCachedCoordinate(maxAge: maxAge) {
            completion(coord)
            return
        }

        // Queue the completion; multiple callers can piggy-back
        completionQueue.append(completion)

        // If we’re already updating, do nothing (completions will be called soon)
        if isUpdating { return }

        // Ensure auth
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // We'll start when delegate notifies us below
        case .denied, .restricted:
            flushCompletions(with: nil)
        default:
            startUpdating(timeout: timeout ?? defaultTimeoutSeconds)
        }
    }

    // MARK: - Private

    private func startUpdating(timeout: TimeInterval) {
        // Cancel any old timers
        stopTimer?.invalidate(); stopTimer = nil
        requestTimer?.invalidate(); requestTimer = nil

        // Start updates (lightweight)
        isUpdating = true
        manager.startUpdatingLocation()

        // Hard timeout to stop the radio
        requestTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.manager.stopUpdatingLocation()
            self.isUpdating = false
            self.flushCompletions(with: self.lastFix?.coordinate)
        }
    }

    private func stopUpdatingSoon(after seconds: TimeInterval = 0.5) {
        stopTimer?.invalidate()
        stopTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.manager.stopUpdatingLocation()
            self?.isUpdating = false
        }
    }

    private func flushCompletions(with coord: CLLocationCoordinate2D?) {
        let callbacks = completionQueue
        completionQueue.removeAll()
        callbacks.forEach { $0(coord) }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // If callers are waiting, begin updates now
            if !completionQueue.isEmpty, !isUpdating {
                startUpdating(timeout: defaultTimeoutSeconds)
            }
        case .denied, .restricted:
            flushCompletions(with: nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let new = locations.last else { return }
        lastFix = new
        if !completionQueue.isEmpty {
            let age = -new.timestamp.timeIntervalSinceNow
            if age <= defaultMaxAgeSeconds {
                flushCompletions(with: new.coordinate)
                stopUpdatingSoon(after: 0.6)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        flushCompletions(with: lastFix?.coordinate)
        manager.stopUpdatingLocation()
        isUpdating = false
    }
}

