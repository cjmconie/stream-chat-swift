//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

internal class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    class var reuseId: String { String(describing: self) }

    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    internal private(set) lazy var messageView = uiConfig.messageList.messageContentView.init().withoutAutoresizingMaskConstraints
    private var hasCompletedStreamSetup = false

    // MARK: - Lifecycle

    override internal func setUpLayout() {
        contentView.addSubview(messageView)

        NSLayoutConstraint.activate([
            messageView.topAnchor.pin(equalTo: contentView.topAnchor),
            messageView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            messageView.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }

    override internal func updateContent() {
        messageView.message = message
    }

    // MARK: - Overrides

    override internal func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }

    override internal func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}

class СhatIncomingMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.leadingAnchor.pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    }
}

class СhatOutgoingMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}

internal typealias СhatMessageAttachmentCollectionViewCell = _СhatMessageAttachmentCollectionViewCell<NoExtraData>

internal class _СhatMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    private var _messageAttachmentContentView: _ChatMessageAttachmentContentView<ExtraData>?
    
    override internal var messageView: _ChatMessageContentView<ExtraData> {
        if let messageContentView = _messageAttachmentContentView {
            return messageContentView
        } else {
            _messageAttachmentContentView = uiConfig
                .messageList
                .messageAttachmentContentView
                .init()
                .withoutAutoresizingMaskConstraints
            return _messageAttachmentContentView!
        }
    }
}

class СhatIncomingMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>:
    _СhatMessageAttachmentCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.leadingAnchor.pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    }
}

class СhatOutgoingMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>:
    _СhatMessageAttachmentCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
