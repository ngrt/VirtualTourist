//
//  PictureCell.swift
//  
//
//  Created by Nawfal on 05/09/2015.
//
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell
{
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(frame: contentView.bounds)
        imageView.contentMode = .ScaleAspectFit
        contentView.addSubview(imageView)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var imageView: UIImageView!
}