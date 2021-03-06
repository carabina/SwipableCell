//
//  ActionsView.swift
//  EditTableViewCell
//
//  Created by ancheng on 2018/5/18.
//  Copyright © 2018年 ancheng. All rights reserved.
//

import UIKit

class ActionsView: UIView {

    private var actionViews: [ActionView] = []

    var preferredWidth: CGFloat = 0
    var isConfirming = false

    var leftMoveWhenConfirm: (() -> Void)?

    init(actions: [SwipedAction]) {

        super.init(frame: .zero)

        clipsToBounds = true

        for action in actions {
            let actionView = ActionView(action: action)

            actionView.beConfirm = { [weak self] in
                self?.isConfirming = true
            }

            actionView.confirmAnimationCompleted = { [weak self] in
                self?.actionViews.filter({ !$0.isConfirming }).forEach({ $0.isHidden = true })
            }
            addSubview(actionView)

            actionViews.append(actionView)
            actionView.toX = preferredWidth
            preferredWidth += actionView.widthConst
        }
    }

    func setProgress(_ progress: CGFloat) {
        for actionView in actionViews {
            actionView.frame.origin.x = actionView.toX * progress
            actionView.frame.size = bounds.size
            actionView.leftMoveWhenConfirm = leftMoveWhenConfirm
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ActionView: UIView {

    var margin: CGFloat = 10

    var beConfirm: (() -> Void)?
    var leftMoveWhenConfirm: (() -> Void)?
    var confirmAnimationCompleted: (() -> Void)?

    var widthConst: CGFloat {
        return action.preferredWidth ?? (action.title.getWidth(withFont: action.titleFont) + 2 * margin)
    }

    var toX: CGFloat = 0

    private var titleLabel = UILabel()
    private let action: SwipedAction
    private var widthConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?

    private(set) var isConfirming = false
    private var isFirstTap = true

    init(action: SwipedAction) {
        self.action = action
        super.init(frame: CGRect.zero)

        margin = action.horizontalMargin
        backgroundColor = action.backgroundColor

        titleLabel.textColor = action.titleColor
        titleLabel.textAlignment = .center
        titleLabel.text = action.title
        titleLabel.numberOfLines = 0
        titleLabel.font = action.titleFont

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        leadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin)
        leadingConstraint?.isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        widthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: widthConst - 2 * margin)
        widthConstraint?.isActive = true

        titleLabel.isUserInteractionEnabled = false

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {

        if case .custom(let title) = action.needConfirm, !isConfirming {

            isConfirming = true
            beConfirm?()
            titleLabel.text = title
            superview?.bringSubview(toFront: self)

            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                [weak self] in
                guard let strongSelf = self else { return }
                self?.frame.origin.x = 0
                self?.widthConstraint?.constant = title.getWidth(withFont: strongSelf.action.titleFont)
                if let superView = strongSelf.superview as? ActionsView {
                    let deleteWidth = title.getWidth(withFont: strongSelf.action.titleFont) + 2 * strongSelf.margin
                    if superView.preferredWidth < deleteWidth {
                        superView.preferredWidth = deleteWidth
                        strongSelf.leftMoveWhenConfirm?()
                    } else {
                        strongSelf.leadingConstraint?.constant = (superView.preferredWidth - title.getWidth(withFont: strongSelf.action.titleFont)) / 2
                    }
                }
                strongSelf.layoutIfNeeded()
                }, completion: { [weak self] (_) in
                    self?.confirmAnimationCompleted?()
            })
        } else {
            if !isFirstTap {
                return
            }
            isFirstTap = false
            action.handler?(action)
        }
    }

}
