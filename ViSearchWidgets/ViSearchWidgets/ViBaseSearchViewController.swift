//
//  BaseSearchViewController.swift
//  ViSearchWidgets
//
//  Created by Hung on 10/11/16.
//  Copyright © 2016 Visenze. All rights reserved.
//

import UIKit
import ViSearchSDK

private let reuseIdentifier = "ViProductCardLayoutCell"


/// Search solutions enum
///
/// - FIND_SIMILAR: find similar search
/// - YOU_MAY_ALSO_LIKE: you may also like search
/// - SEARCH_BY_IMAGE: search by image
/// - SEARCH_BY_COLOR: search by color
public enum ViSearchType : Int {
    
    case FIND_SIMILAR
    
    case YOU_MAY_ALSO_LIKE
    
    case SEARCH_BY_IMAGE
    
    case SEARCH_BY_COLOR
    
}


/// Border type enum. Used to indicate which border to add for product card
///
/// - TOP: add top border
/// - BOTTOM: add bottom border
/// - LEFT: add left border
/// - RIGHT: add right border
public enum ViBorderType : Int {
    case TOP
    case BOTTOM
    case LEFT
    case RIGHT
}


/// delegate for all search controllers. All methods are optional
public protocol ViSearchViewControllerDelegate: class {
    
    /// configure the collectionview cell before displaying
    func configureCell(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath , cell: UICollectionViewCell)
    
    /// configure the layout if necessary
    func configureLayout(sender: AnyObject, layout: UICollectionViewFlowLayout)
    
    /// product selection notification i.e. user tap on a product card
    func didSelectProduct(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// action button tapped notification i.e. user tap on action button at the top right corner of a product card cell
    func actionBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// allow configuration of the FindSimilar controller when similar button is tapped
    /// This is triggered before the similar controller is pushed to navigation controller/shown in modal
    func willShowSimilarController(sender: AnyObject, controller: ViFindSimilarViewController, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// user tapped on similar button at the bottom right of a product card cell
    func similarBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// allow configuration of the filter controller before showing
    func willShowFilterController(sender: AnyObject, controller: ViFilterViewController)
    
    
    /// Successful search after refreshData() method is called
    ///
    /// - Parameters:
    ///   - searchType: the recent search type
    ///   - reqId: recent request id
    ///   - products: list of extract products information based on mapping
    func searchSuccess( searchType: ViSearchType, reqId: String? , products: [ViProduct])
    
    
    /// Search failed callback
    ///
    /// - Parameters:
    ///   - err: Errors when trying to call the API e.g. network related errors like offline Internet connection
    ///   - apiErrors: errors returned to ViSenze server e.g. due to invalid/missing search parameters
    func searchFailed(err: Error?, apiErrors: [String])
    
}

// make all method optional
public extension ViSearchViewControllerDelegate{
    func configureCell(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath , cell: UICollectionViewCell) {}
    func configureLayout(sender: AnyObject, layout: UICollectionViewFlowLayout) {}
    func didSelectProduct(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    func actionBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    func similarBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    func willShowSimilarController(sender: AnyObject, controller: ViFindSimilarViewController, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    
    func willShowFilterController(sender: AnyObject, controller: ViFilterViewController){}
    
    func searchSuccess( searchType: ViSearchType, reqId: String? , products: [ViProduct]){}
    func searchFailed(err: Error?, apiErrors: [String]){}
    
}

// subclass implementation
public protocol ViSearchViewControllerProtocol: class {
    // configure the flow layout
    func reloadLayout() -> Void
    
    // call Visearch API and refresh data
    func refreshData() -> Void
    
    // return custom static footer view at bottom if necessary
    func footerView() -> UIView?
    
    // return custom static header view at the top if necessary
    func headerView() -> UIView?
    
}


/// Base controller for all search widgets
open class ViBaseSearchViewController: UIViewController , UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ViSearchViewControllerProtocol, ViProductCellDelegate {
    
    public let headerCollectionViewCellReuseIdentifier = "ViHeaderReuseCellId"
    
    /// collection view that holds the search results
    public var collectionView : UICollectionView? {
        let resultsView = self.view as! ViSearchResultsView
        return resultsView.collectionView
    }
    
    /// associated collection view layout
    public var collectionViewLayout: UICollectionViewLayout {
        let resultsView = self.view as! ViSearchResultsView
        return resultsView.collectionViewLayout
    }
    
    /// title label. Used for displaying the widget title in header view
    /// Currently this is only used for "You May Also Like" widget
    public var titleLabel : UILabel?
    
    /// show/hide the title label in header
    public var showTitleHeader: Bool = true
    
    // MARK: Important properties
    
    /// delegate for various events
    public weak var delegate: ViSearchViewControllerDelegate?
    
    /// last known successful search request Id to Visenze API
    public var reqId : String? = ""
    
    /// search parameters
    public var searchParams: ViBaseSearchParams? = nil
    
    /// schema mappings to UI elements
    public var schemaMapping: ViProductSchemaMapping = ViProductSchemaMapping()
    
    // MARK: UI settings
    
    /// UI settings
    
    /// Configuration for product image
    public var imageConfig: ViImageConfig = ViImageConfig()
    
    /// Configuration for heading view e.g. for displaying product tile
    public var headingConfig: ViLabelConfig = ViLabelConfig.default_heading_config
    
    /// Configuring for label view e.g. displaying brand in label
    public var labelConfig: ViLabelConfig = ViLabelConfig.default_label_config
    
    /// Configuration for product price
    public var priceConfig: ViLabelConfig = ViLabelConfig.default_price_config
    
    /// Configuration for discount price
    public var discountPriceConfig: ViLabelConfig = ViLabelConfig.default_discount_price_config
    
    /// true if similar button (at bottom right) is available for a product card in search results
    public var hasSimilarBtn: Bool = true
    
    /// Configuration for similar button if available
    public var similarBtnConfig: ViButtonConfig = ViButtonConfig.default_similar_btn_config
    
    /// true if action button (at top right) is available for a product card in search results
    /// The default action button is the heart icon with add to wish list action tracked when tapped
    public var hasActionBtn: Bool = true
    
    /// Configuration for action button if available
    public var actionBtnConfig: ViButtonConfig = ViButtonConfig.default_action_btn_config
    
    /// background color for a product card in the search results
    public var productCardBackgroundColor: UIColor = ViTheme.sharedInstance.default_product_card_background_color
    
    /// product card border color. Default to no border
    public var productCardBorderColor: UIColor? = nil
    
    /// product card border width. Default to 0 for no border
    public var productCardBorderWidth : CGFloat = 0
    
    /// which border(s) to draw for the product card
    /// by default all borders are drawn
    public var productBorderStyles : [ViBorderType] = [.LEFT , .RIGHT , .BOTTOM , .TOP]
    
    
    /// show/hide Power by Visenze image
    public var showPowerByViSenze : Bool = true
    
    /// extract products data from ViSenze API response
    public var products: [ViProduct] = [] {
        didSet {
            // make sure that this is run on ui thread
            DispatchQueue.main.async {
                self.reloadLayout()
            }
        }
    }
    
    /// product card size
    public var itemSize: CGSize = CGSize(width: 1, height: 1) {
        didSet {
            reloadLayout()
        }
    }
    
    /// Spacing between product items on same row
    public var itemSpacing  : CGFloat = 4.0 {
        didSet{
            reloadLayout()
        }
    }
    
    /// view background color
    public var backgroundColor  : UIColor = UIColor.white
    
    /// left padding
    public var paddingLeft: CGFloat = 0 {
        didSet{
            reloadLayout()
        }
    }

    /// right padding
    public var paddingRight: CGFloat = 0 {
        didSet{
            reloadLayout()
        }
    }

    // MARK: init methods
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    open func setup(){
        self.titleLabel = UILabel()
        self.titleLabel?.textAlignment = .left
        self.titleLabel?.font = ViTheme.sharedInstance.default_widget_title_font
        
        // Important: without this the header above collection view will appear behind the navigation bar
        self.edgesForExtendedLayout = []
    }
    
    open override func loadView() {
        let searchResultsView = ViSearchResultsView(frame: .zero)
        self.view = searchResultsView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
        
        // Register cell classes
        self.collectionView!.register(ViProductCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCollectionViewCellReuseIdentifier)
        
        reloadLayout()
    }
    
    // MARK: UICollectionView datasource & delegate
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        
        return .zero
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ViProductCollectionViewCell
        
        let product = products[indexPath.row]
        if let url =  product.imageUrl {
            let productCardLayout = ViProductCardLayout(
                imgUrl: url, imageConfig: self.imageConfig,
                heading: product.heading, headingConfig: self.headingConfig ,
                label: product.label, labelConfig: self.labelConfig,
                price: product.price, priceConfig: self.priceConfig,
                discountPrice: product.discountPrice, discountPriceConfig: self.discountPriceConfig,
                hasSimilarBtn: self.hasSimilarBtn, similarBtnConfig: self.similarBtnConfig,
                hasActionBtn: self.hasActionBtn, actionBtnConfig: self.actionBtnConfig,
                pricesHorizontalSpacing: ViProductCardLayout.default_spacing, labelLeftPadding: ViProductCardLayout.default_spacing)
            
            let productView = productCardLayout.arrangement( origin: .zero ,
                                                             width:  itemSize.width ,
                                                             height: itemSize.height).makeViews(in: cell.contentView)
            
            productView.backgroundColor = self.productCardBackgroundColor
            
            if let borderColor = self.productCardBorderColor {
                if self.productBorderStyles.count == 4 {
                    productView.addBorder(width: self.productCardBorderWidth, color: borderColor)
                }
                else {
                    for style in self.productBorderStyles {
                        switch style {
                            case .BOTTOM:
                                productView.addBorderBottom(size: self.productCardBorderWidth, color: borderColor)
                            
                            case .LEFT:
                                productView.addBorderLeft(size: self.productCardBorderWidth, color: borderColor)
                            
                            case .RIGHT:
                                productView.addBorderRight(size: self.productCardBorderWidth, color: borderColor)
                            
                            case .TOP:
                                productView.addBorderTop(size: self.productCardBorderWidth, color: borderColor)
                            
                        }
                    }
                }

            }
            
            cell.delegate = self
            
            if self.hasSimilarBtn {
                // wire up similar button action
                if let similarBtn = productView.viewWithTag(ViProductCardTag.findSimilarBtnTag.rawValue) as? UIButton {
                    // add event
                    similarBtn.addTarget(cell, action: #selector(ViProductCollectionViewCell.similarBtnTapped(sender:)), for: .touchUpInside)
                }
            }
            
            if self.hasActionBtn {
                // wire up similar button action
                if let actionBtn = productView.viewWithTag(ViProductCardTag.actionBtnTag.rawValue) as? UIButton {
                    // add event
                    actionBtn.addTarget(cell, action: #selector(ViProductCollectionViewCell.actionBtnTapped(sender:)), for: .touchUpInside)
                }
            }
            
        }
        
        if let delegate = delegate {
            delegate.configureCell(sender: self, collectionView: collectionView, indexPath: indexPath, cell: cell)
        }
        
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate {
            let product = products[indexPath.row]
            
            if let reqId = self.reqId {
                let params = ViTrackParams(reqId: reqId, action: ViDefaultTrackingAction.CLICK.rawValue)
                params?.imName = product.im_name
                
                ViSearch.sharedInstance.track(params: params!) { (success, error) in
                    
                }
            }
            
            delegate.didSelectProduct(sender: self, collectionView: collectionView, indexPath: indexPath, product: product)
        }
    }
    
    // MARK: Important methods
    
    /// estimate product card item size based on image width in image config
    open func estimateItemSize() -> CGSize{
        return self.estimateItemSize(constrainedToWidth: self.imageConfig.size.width)
    }
    
    /// estimate product card item size for a max width of maxWidth
    /// depend on the product configurations e.g. label is optional, the height would be dynamic and changes
    open func estimateItemSize(constrainedToWidth maxWidth: CGFloat) -> CGSize{
        
        let productCardLayout = ViProductCardLayout(
            imgUrl: nil, imageConfig: self.imageConfig,
            heading: self.schemaMapping.heading , headingConfig: self.headingConfig ,
            label: self.schemaMapping.label , labelConfig: self.labelConfig,
            price: (self.schemaMapping.price == nil ? nil : 0), priceConfig: self.priceConfig,
            discountPrice: (self.schemaMapping.discountPrice == nil ? nil : 0), discountPriceConfig: self.discountPriceConfig,
            hasSimilarBtn: self.hasSimilarBtn, similarBtnConfig: self.similarBtnConfig,
            hasActionBtn: self.hasActionBtn, actionBtnConfig: self.actionBtnConfig,
            pricesHorizontalSpacing: ViProductCardLayout.default_spacing, labelLeftPadding: ViProductCardLayout.default_spacing)
        
        return productCardLayout.arrangement(origin: .zero, width: maxWidth).frame.size
    }
    
    /// to be override by subclasses. Subclass must call delegate.configureLayout to allow further customatization
    open func reloadLayout(){
       
        // initial setup will skeep this
        if self.itemSize.width < 2 {
            return
        }
        
        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.footerReferenceSize = .zero
        self.collectionView?.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        layout.itemSize = itemSize
        
        let searchResultsView = self.view as! ViSearchResultsView
        
        searchResultsView.paddingLeft = paddingLeft
        searchResultsView.paddingRight = paddingRight
        
        // static header
        if self.headerSize.height > 0 {
            if let headerView = self.headerView() {
                searchResultsView.setHeader(headerView)
            }
        }
        searchResultsView.headerHeight = self.headerSize.height
        
        // static footer
        if self.footerSize.height > 0 {
            if let footerView = self.footerView() {
                searchResultsView.setFooter(footerView)
            }
        }
        searchResultsView.footerHeight = self.footerSize.height
        
        searchResultsView.setNeedsLayout()
        searchResultsView.layoutIfNeeded()
          
    }
    
    
    /// Set the meta query parameters based on provided schema mapping
    /// The parameters are needed to retrieve the relevant product information
    open func setMetaQueryParamsForSearch() {
        
        if let searchParams = self.searchParams {
            // construct the fl based on schema mappings
            // need to merge the array to make sure that the returned data contain the relevant meta data in mapping
            let metaArr = self.schemaMapping.getMetaArrForSearch()
            let combinedArr = searchParams.fl + metaArr
            let flSet = Set(combinedArr)
            searchParams.fl = Array(flSet)
        }
        
    }
    
    /// to be implemented by subclasses to call ViSenze APIs and refresh views
    open func refreshData(){}
    
   
    //MARK: header
    
    /// fixed header size
    open var headerSize : CGSize {
        if !showTitleHeader {
            return .zero
        }
        
        if self.title != nil {
            return CGSize(width: self.view.bounds.width, height: ViTheme.sharedInstance.default_widget_title_font.lineHeight + 4)
        }
        return .zero
    }
    
    
    /// By default return a UILabel that shows the widget/view controller title
    /// For example, return "You May Also Like" header in "You May Also Like" widget solution
    ///
    /// - Returns: header view at the top
    open func headerView() -> UIView? {
        if !showTitleHeader {
            return nil
        }
        
        if let title = self.title, let label = self.titleLabel {
            label.text = title
            label.sizeToFit()
            
            return label
        }
        return nil
    }
    
    
    // MARK: footer - Power by ViSenze
    
    
    /// By default, return Power By ViSenze image view and positions it at the bottom right of the footer
    ///
    /// - Returns: footer view
    open func footerView() -> UIView? {
        
        if !showPowerByViSenze {
            return nil
        }
        
        let powerImgView = UIImageView(image: ViIcon.power_visenze)
        
        var width = footerSize.width
        var height = footerSize.height
        
        if let img = ViIcon.power_visenze {
            width = min(width, img.size.width)
            height = min(height, img.size.height)
        }
        
        powerImgView.frame = CGRect(x: (self.view.bounds.width - width - 2), y: 4 , width: width, height: height )
        powerImgView.backgroundColor = ViTheme.sharedInstance.default_btn_background_color
        
        // fix rotation issue
        powerImgView.autoresizingMask = [ .flexibleLeftMargin , .flexibleRightMargin ]
        
        return powerImgView
    }
    
    /// footer size
    open var footerSize : CGSize {
        
        if !showPowerByViSenze {
            return CGSize.zero
        }
        
        // hide footer if there is no product
        if self.products.count == 0 {
            return CGSize.zero
        }
        return CGSize(width: 100, height: 25)
    }

    
    // MARK: buttons events
    
    /// user clicks on "Similar" button on a product card cell
    /// Copy the revelvant parameters from current search and open the "Find Similar" view controller
    @IBAction open func similarBtnTapped(_ cell: ViProductCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell) {
            let product = products[indexPath.row]
            
            // go to similar button page
            if let params = ViSearchParams(imName: product.im_name) , let curParams = self.searchParams {
            
                let similarController = ViFindSimilarViewController()
                
                // copy parameters over
                
                // copy all the parameters over from original query
                params.fl = curParams.fl
                params.fq = curParams.fq
                params.detection = curParams.detection
                params.getAllFl = curParams.getAllFl
                params.limit = 16
                
                similarController.searchParams = params
                
                // copy other settings
                similarController.schemaMapping = self.schemaMapping
                
                similarController.imageConfig = self.imageConfig
                
                similarController.labelConfig = self.labelConfig
                similarController.headingConfig = self.headingConfig
                similarController.priceConfig = self.priceConfig
                similarController.discountPriceConfig = self.discountPriceConfig
                similarController.hasActionBtn = self.hasActionBtn
                similarController.actionBtnConfig = self.actionBtnConfig
                similarController.hasSimilarBtn = self.hasSimilarBtn
                similarController.similarBtnConfig = self.similarBtnConfig
                similarController.showPowerByViSenze = self.showPowerByViSenze
                similarController.productCardBackgroundColor = self.productCardBackgroundColor
                similarController.backgroundColor = self.backgroundColor
                similarController.itemSpacing = self.itemSpacing
                if self is ViGridSearchViewController {
                    let gridController = self as! ViGridSearchViewController
                    similarController.rowSpacing = gridController.rowSpacing
                    
                    // copy the filtering parameters also
                    similarController.filterControllerTitle = gridController.filterControllerTitle
                    
                    // copy the filter params
                    if gridController.filterItems.count > 0 {
                        var filterItems : [ViFilterItem] = []
                        
                        for filterItem in gridController.filterItems {
                            filterItems.append(filterItem.clone())
                        }
                        
                        similarController.filterItems = filterItems
                    }
                    
                }
                
                similarController.productCardBorderColor = self.productCardBorderColor
                similarController.productCardBorderWidth = self.productCardBorderWidth
                
                let width = similarController.estimateItemWidth(numOfColumns: 2, containerWidth: self.view.bounds.width)
                // make sure image width is less than item width
                similarController.imageConfig.size.width = min(width, similarController.imageConfig.size.width)
                let similarItemSize = CGSize(width: width, height: self.itemSize.height )
                
                similarController.itemSize = similarItemSize
                
                similarController.setItemWidth(numOfColumns: 2, containerWidth: self.view.bounds.width)
                similarController.showTitleHeader = false
                similarController.queryProduct = product
                
                similarController.queryImageConfig = similarController.generateQueryImageConfig(scale: ViTheme.sharedInstance.default_query_product_image_scale)
                similarController.showQueryProduct = true
                
                // set to same delegate
                similarController.delegate = self.delegate
                
                // present this controller as modal view controller wrapped in navigation controller
                if(self.navigationController == nil) {
                    let backItem = UIBarButtonItem(image: ViIcon.back, style: .plain, target: self, action: #selector(dimissSimilarController))
                    similarController.navigationItem.leftBarButtonItem = backItem
                    
                    let navController = UINavigationController(rootViewController: similarController)
                    navController.modalPresentationStyle = .fullScreen
                    navController.modalTransitionStyle = .coverVertical
                    
                    delegate?.willShowSimilarController(sender: self, controller: similarController, collectionView: self.collectionView!, indexPath: indexPath, product: product)
                    
                    // TODO: test this flow when navigation controller is not available
                    self.show(navController, sender: self)
                }
                else {
                    
                    self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style: .plain, target:nil, action:nil)
                    
                    delegate?.willShowSimilarController(sender: self, controller: similarController, collectionView: self.collectionView!, indexPath: indexPath, product: product)
                    
                    self.navigationController?.pushViewController(similarController, animated: true)
                }
                
                
                similarController.refreshData()
                
            }
            
            delegate?.similarBtnTapped(sender: self, collectionView: self.collectionView!, indexPath: indexPath, product: product)
        }
    }
    
    /// user tapped on action button of a product card cell
    @IBAction open func actionBtnTapped(_ cell: ViProductCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell) {
            let product = products[indexPath.row]
            
            if let reqId = self.reqId, let action = self.actionBtnConfig.actionToRecord {
                let params = ViTrackParams(reqId: reqId, action: action)
                params?.imName = product.im_name
                
                // track the action
                ViSearch.sharedInstance.track(params: params!) { (success, error) in
                    
                }
            }
            
            delegate?.actionBtnTapped(sender: self, collectionView: self.collectionView!, indexPath: indexPath, product: product)
        }
    }
    
    /// dismiss the similar controller that is being presented when user click on "Similar" button of a product card
    open func dimissSimilarController() {
        self.dismiss(animated: true, completion: nil)
    }
    

}