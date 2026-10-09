import AVFoundation

/// The app's five short sound effects (design.md §1.6). Uses the ambient audio session, so the iPhone's
/// silent switch mutes them and they mix with music instead of stopping it. All are loaded at launch
/// so they play without a delay. Files and licenses: `docs/credits.md`.
final class SoundPlayer {
    enum Sound: String, CaseIterable {
        /// Check-in submitted: a bright ding.
        case checkIn = "checkin"
        /// The celebration: a short cheerful flourish.
        case celebration
        /// A skip is used: a soft whoosh.
        case skip
        /// A streak ends: a low, gentle bloop.
        case streakEnded
        /// The flame reaches a new form: a bigger rising flourish.
        case evolution

        /// Played a little quieter than the file, where the sound should stay soft.
        var volume: Float {
            switch self {
            case .skip: 0.5
            case .streakEnded: 0.7
            case .checkIn, .celebration, .evolution: 0.9
            }
        }
    }

    static let shared = SoundPlayer()

    private var players: [Sound: AVAudioPlayer] = [:]

    /// Sets up the ambient session and loads every sound. Called once at launch.
    func preload() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for sound in Sound.allCases where players[sound] == nil {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = sound.volume
            player.prepareToPlay()
            players[sound] = player
        }
    }

    /// Plays a sound from the start, unless Settings → Sounds is off.
    func play(_ sound: Sound, enabled: Bool) {
        guard enabled else { return }
        if players[sound] == nil { preload() }
        guard let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }

    /// Whether every sound file is in the app bundle (tests).
    static var allFilesPresent: Bool {
        Sound.allCases.allSatisfy { Bundle.main.url(forResource: $0.rawValue, withExtension: "caf") != nil }
    }
}
