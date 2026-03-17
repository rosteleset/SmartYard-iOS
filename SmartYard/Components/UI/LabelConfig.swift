import UIKit

struct LabelConfig {
    var font: UIFont
    var color: UIColor
    var alignment: NSTextAlignment
    var numberOfLines: Int
    var lineBreakMode: NSLineBreakMode
    var adjustsFontSizeToFitWidth: Bool
    var minimumScaleFactor: CGFloat
}

extension LabelConfig {
    static let title = LabelConfig(
        font: .SourceSansPro.bold(size: 32),
        color: UIColor(red: 0.953, green: 0.957, blue: 0.980, alpha: 1.0),
        alignment: .left,
        numberOfLines: 1,
        lineBreakMode: .byTruncatingTail,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let sectionHeader = LabelConfig(
        font: .SourceSansPro.regular(size: 16),
        color: .SmartYard.gray,
        alignment: .left,
        numberOfLines: 1,
        lineBreakMode: .byTruncatingTail,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let bodyRegular = LabelConfig(
        font: .SourceSansPro.regular(size: 14),
        color: .SmartYard.semiBlack,
        alignment: .left,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let bodySemibold = LabelConfig(
        font: .SourceSansPro.semibold(size: 18),
        color: .SmartYard.semiBlack,
        alignment: .left,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )
}
