import SwiftUI
import WatchKit
import UserNotifications
import os

/// The watchOS app's entry point.
/// Hosts `ContentView` in the single window and installs `AppDelegate` as the
/// application delegate, passing the delegate's `AppPresenter` to the view.
@main
struct imon_Watch_AppApp: App {

    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(appPresenter: appDelegate.appPresenter)
        }
    }
}

/// Receives watchOS application lifecycle events and background wakes.
/// The one object the OS targets for launch, activation, background refresh
/// tasks, and notification presentation, so those hooks all live here.
final class AppDelegate: NSObject, WKApplicationDelegate {

    /// The app's one lifecycle presenter. Owned here rather than by the view
    /// so a background wake reaches the live `PetPresenter` when one exists,
    /// keeping a single writer for the save.
    let appPresenter = AppPresenter()

    /// Handles application launch, installing this delegate so notification
    /// events — including foreground care reminders — arrive here.
    func applicationDidFinishLaunching() {
        Log.presentation.info("App launched")
        UNUserNotificationCenter.current().delegate = self
        // Permission prompts wait until the pet is alive — see `PermissionRequester`.
    }

    /// Logs the app becoming active.
    func applicationDidBecomeActive() {
        Log.presentation.debug("App became active")
    }

    /// Re-arms the next background wake before the app leaves the foreground.
    func applicationWillResignActive() {
        Log.presentation.debug("App will resign active")
        // Always leave one refresh pending when heading to the background, so a
        // throttled or failed wake doesn't break the chain.
        BackgroundRefreshScheduler.live().scheduleNext(from: Date())
    }

    /// Routes each delivered background task to its handler.
    /// Only refresh tasks do work, via `handleRefresh`; snapshot and unknown
    /// tasks complete immediately without advancing the pet.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refresh as WKApplicationRefreshBackgroundTask:
                handleRefresh(refresh)
            case let snapshot as WKSnapshotRefreshBackgroundTask:
                snapshot.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: .distantFuture,
                    userInfo: nil
                )
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    /// Ticks the pet through `PetActionRouter`, which advances, replans
    /// reminders and re-arms the next wake, then completes the task. The live
    /// presenter takes the tick when the app holds one; otherwise the offline
    /// session reads the persisted Steps and Notifications switches the
    /// foreground honours.
    private func handleRefresh(_ task: WKApplicationRefreshBackgroundTask) {
        Task { @MainActor in
            let offline = appPresenter.offlineDependencies(
                witnesses: CareHandoff.Witnesses(notifications: .live(), complications: .live()),
                refresh: .live()
            )
            _ = await PetActionRouter.perform(.tick, app: appPresenter, offline: offline, now: Date())
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Shows care reminders even while the app is in the foreground — otherwise
    /// watchOS silently drops them when the screen is on the app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
