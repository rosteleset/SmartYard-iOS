import UIKit

extension UILabel {
    static func make(
        _ config: LabelConfig,
        text: String? = nil
    ) -> UILabel {
        let label = UILabel()
        label.font = config.font
        label.textColor = config.color
        label.textAlignment = config.alignment
        label.numberOfLines = config.numberOfLines
        label.lineBreakMode = config.lineBreakMode
        label.adjustsFontSizeToFitWidth = config.adjustsFontSizeToFitWidth
        label.minimumScaleFactor = config.minimumScaleFactor
        label.text = text
        return label
    }

    func apply(config: LabelConfig) {
        font = config.font
        textColor = config.color
        textAlignment = config.alignment
        numberOfLines = config.numberOfLines
        lineBreakMode = config.lineBreakMode
        adjustsFontSizeToFitWidth = config.adjustsFontSizeToFitWidth
        minimumScaleFactor = config.minimumScaleFactor
    }
}
