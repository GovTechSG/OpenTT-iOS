//
//  SEFavouriteNoResultFound.swift
//  OpenTraceTogether

import UIKit

class SEFavouriteNoResultFound: UIView {

    @IBOutlet var noSearchResultsFoundContentView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        noFavouritesCommonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        noFavouritesCommonInit()
    }

    private func noFavouritesCommonInit() {
        Bundle.main.loadNibNamed("SEFavouriteNoResultFound", owner: self, options: nil)
        addSubview(noSearchResultsFoundContentView)
        noSearchResultsFoundContentView.frame = self.bounds
        noSearchResultsFoundContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

}
