import Foundation
@testable import imon_Watch_App

nonisolated extension WeatherProvider {
    /// Creates a provider that fails every fetch with the given error.
    static func mockFailing(
        _ error: WeatherError = .weatherUnavailable
    ) -> WeatherProvider {
        WeatherProvider { throw error }
    }
}

nonisolated extension StepCountProvider {
    /// Builds a test witness reporting `steps` for any day, past days included.
    static func mock(steps: Int = 0) -> StepCountProvider {
        StepCountProvider(fetchTodaySteps: { steps })
    }
}
