#if DEBUG && UIPREVIEW
import UIKit
import Model

/// Class for quickly testing and iterating on UI. Only compiled and presented when the active compiler
/// flags `DEBUG` and `UIPREVIEW` are both set in Build Settings.
final class DebugUIViewController: DeclarativeViewController {
  private let currentGlory = State(initialValue: "1045")
  private let playerRank = State(initialValue: GloryRank.brave(.III))
  private lazy var playerRankText = playerRank.binding.map { String(describing: $0) }

  private let gloryToNextRank = State(initialValue: 5)
  private let winsToNextRank = State<UInt>(initialValue: 1)

  private let currentWinStreak = State<UInt>(initialValue: 1)
  private let matchesPlayedThisWeek = State(initialValue: 2)
  private let matchesWonThisWeek = State(initialValue: 1)

  private let matchesRemainingForWeeklyBonus = State(initialValue: 1)
  private lazy var metWeeklyBonus = matchesRemainingForWeeklyBonus.binding.map { $0 == 0 }
  private let willRankUp = State(initialValue: true)
  private let gloryAtNextWeeklyReset = State(initialValue: 1253)
  private let optimisticGloryAtNextWeeklyReset = State(initialValue: 1253)
  private lazy var currentRankDecays = playerRank.binding.map { $0 >= .mythic(.I) }

  private let winsToFabled = State(initialValue: "9")
  private lazy var winsToFabledIsZero = winsToFabled.binding.map { Int($0) == 0 }
  private lazy var moreWinsText = winsToFabled.binding.map { "  more win" + (Int($0) != 1 ? "s" : "") }


  override var layout: Layout {
    return
      Layout(in: view,
        StackView(.vertical, [
          Spacer(.flexible),

          //MARK: Player Name, Glory & Rank

          Text("starmunk")
            .font(Style.Font.title)
            .fontSize(36)
            .adjustsFontSizeRelativeToDisplay(.x375)
            .color(.white),

          Spacer(DisplayScale.x375.scale(8)),

          Text(currentGlory.binding)
            .fontSize(22)
            .adjustsFontSizeRelativeToDisplay(.x375)
            .color(.white)
          +
          Text(" Glory   —   ")
            .fontSize(22)
            .adjustsFontSizeRelativeToDisplay(.x375)
            .color(.white)
          +
          Text(playerRankText)
            .fontSize(22)
            .adjustsFontSizeRelativeToDisplay(.x320)
            .color(.red),

          Spacer(DisplayScale.x320.scale(12)),

          NextRankupCard(gloryRemaining: gloryToNextRank.binding, winsRemaining: winsToNextRank.binding),
          Spacer(DisplayScale.x375.scale(18)),
          RecentActivityCard(winStreak: currentWinStreak.binding, matchesPlayed: matchesPlayedThisWeek.binding, matchesWon: matchesWonThisWeek.binding),
          Spacer(DisplayScale.x375.scale(18)),
          WeeklyBonusCard(bonusMet: metWeeklyBonus, rankingUp: willRankUp.binding, matchesRemaining: matchesRemainingForWeeklyBonus.binding, realGlory: gloryAtNextWeeklyReset.binding, optimisticGlory: optimisticGloryAtNextWeeklyReset.binding, currentRankDecays: currentRankDecays),

          //MARK: Wins to Fabled

          Spacer(DisplayScale.x320.scale(12)),

          Text(winsToFabled.binding)
            .font(Style.Font.heading)
            .adjustsFontSizeRelativeToDisplay(.x320)
            .transforming(when: winsToFabledIsZero) { $0.textColor = .white }
            .transforming(when: winsToFabledIsZero, is: false) { $0.textColor = .red }
          +
          Text(moreWinsText)
            .font(Style.Font.heading)
            .adjustsFontSizeRelativeToDisplay(.x320)
            .color(Style.Color.text)
          +
          Text(" to reach Fabled")
            .adjustsFontSizeRelativeToDisplay(.x320)
            .color(Style.Color.text),

          //MARK: Change Account, Refresh, & More Info
          
          Spacer(.flexible),
//          Spacer(DisplayScale.x375.scale(16)),

          StackView(.horizontal, [
            Button(#imageLiteral(resourceName: "escape_regular_m"))
//              .observe(with: onChangePlayerPressed)
              .size(22)
              .tintColor(Style.Color.deemphasized),

            Spacer(50),

            Button(#imageLiteral(resourceName: "refresh_regular_m"))
              .observe(with: onRefreshPressed)
              .size(22)
              .tintColor(Style.Color.interactive),

            Spacer(50),

            Button(#imageLiteral(resourceName: "question_regular_m"))
              .observe(with: onMoreInfoPressed)
              .size(23)
              .tintColor(Style.Color.deemphasized),
          ])
          .adjustsSpacingRelativeToDisplay(.x320)
          .alignment(.center)
        ])
        .alignment(.center)
      )
      .pinned([.leading, .trailing])
      .pinned([.top], padding: UIDevice.current.isRunningIOS10 ? 20 : 0)
      .pinned([.bottom], padding: UIDevice.current.hasHomeButton ? 8 : 0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = Style.Color.background

    currentGlory.broadcast()
    playerRank.broadcast()

    gloryToNextRank.broadcast()
    winsToNextRank.broadcast()

    currentWinStreak.broadcast()
    matchesPlayedThisWeek.broadcast()
    matchesWonThisWeek.broadcast()

    matchesRemainingForWeeklyBonus.broadcast()
    willRankUp.broadcast()
    gloryAtNextWeeklyReset.broadcast()
    optimisticGloryAtNextWeeklyReset.broadcast()

    winsToFabled.broadcast()
  }

  private var refreshAnimator: UIActivityIndicatorView?
  private func onRefreshPressed(_ sender: UIButton) {
    if refreshAnimator == nil {
      refreshAnimator = UIActivityIndicatorView(style: .white)
      refreshAnimator!.translatesAutoresizingMaskIntoConstraints = false
      refreshAnimator!.hidesWhenStopped = true
      refreshAnimator!.backgroundColor = .black

      sender.superview!.addSubview(refreshAnimator!)

      NSLayoutConstraint.activate([
        refreshAnimator!.widthAnchor.constraint(equalTo: sender.superview!.widthAnchor),
        refreshAnimator!.heightAnchor.constraint(equalTo: sender.superview!.heightAnchor),
        refreshAnimator!.centerXAnchor.constraint(equalTo: sender.superview!.centerXAnchor),
        refreshAnimator!.centerYAnchor.constraint(equalTo: sender.superview!.centerYAnchor)
      ])

      refreshAnimator!.startAnimating()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.666) {
        self.refreshAnimator!.stopAnimating()
        self.refreshAnimator!.removeFromSuperview()
        self.refreshAnimator = nil

        //Simulate view model update
        self.currentGlory.binding.emit(String(Int.random(in: 0...5500)))
        self.playerRank.binding.emit(GloryRank.allRanks[Int.random(in: 0..<GloryRank.allRanks.count)])

        self.gloryToNextRank.binding.emit(Int.random(in: 1...666))
        self.winsToNextRank.binding.emit(UInt.random(in: 1...20))

        self.currentWinStreak.binding.emit(UInt.random(in: 0...20))
        self.matchesPlayedThisWeek.binding.emit(Int.random(in: 0...200))
        self.matchesWonThisWeek.binding.emit(Int.random(in: 0...200))

        self.matchesRemainingForWeeklyBonus.binding.emit(Int.random(in: 0...3))
        self.willRankUp.binding.emit(Bool.random())
        self.gloryAtNextWeeklyReset.binding.emit(Int.random(in: 120...5500))
        self.optimisticGloryAtNextWeeklyReset.binding.emit(Int.random(in: 120...5500))

        self.winsToFabled.binding.emit(String(Int.random(in: 0...20)))
      }
    }
  }

  private func onMoreInfoPressed() {
    present(MoreInfoViewController(), animated: true)
  }

  required init(coder: NSCoder = .empty) {
    super.init(nibName: nil, bundle: nil)
  }
}

#endif
