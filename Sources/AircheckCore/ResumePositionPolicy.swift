import Foundation

public enum ResumePositionPolicy {
    public static func startTime(saved: TimeInterval?, duration: TimeInterval) -> TimeInterval {
        guard duration > 0,
              let saved,
              saved > 0,
              saved < duration - 30
        else { return 0 }
        return saved
    }
}
