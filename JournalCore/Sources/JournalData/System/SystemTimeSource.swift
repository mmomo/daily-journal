import Foundation
import JournalDomain

public struct SystemTimeSource: TimeSource {
    public init() {}
    public var now: Date { Date() }
    public var timeZone: TimeZone { .autoupdatingCurrent }
}
