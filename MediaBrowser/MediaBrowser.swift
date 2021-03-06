//
//  MediaBrowser.swift
//  MediaBrowser
//
//  Created by Seungyoun Yi on 2017. 9. 6..
//  Copyright © 2017년 Seungyoun Yi. All rights reserved.
//

import UIKit
import MediaPlayer
import QuartzCore
import SDWebImage

func floorcgf(x: CGFloat) -> CGFloat {
    return CGFloat(floorf(Float(x)))
}

/// MediaBrwoser is based in UIViewController, UIScrollViewDelegate and UIActionSheetDelegate. So you can push, or make modal.
public class MediaBrowser: UIViewController, UIScrollViewDelegate, UIActionSheetDelegate {
    private let padding = CGFloat(10.0)

    // Data
    private var mediaCount = -1
    private var mediaArray = [Media?]()
    private var thumbMedias = [Media?]()
	private var fixedMediasArray: [Media]? // Provided via init
	
	// Views
	private var pagingScrollView = UIScrollView()
	
	// Paging & layout
	private var visiblePages = Set<MediaZoomingScrollView>()
    private var recycledPages = Set<MediaZoomingScrollView>()
	private var currentPageIndex = 0
    private var previousPageIndex = Int.max
    private var previousLayoutBounds = CGRect.zero
	private var pageIndexBeforeRotation = 0
	
	// Navigation & controls
	private var toolbar = UIToolbar()
	private var controlVisibilityTimer: Timer?
	private var previousButton: UIBarButtonItem?
    private var nextButton: UIBarButtonItem?
    private var actionButton: UIBarButtonItem?
    private var doneButton: UIBarButtonItem?
    
    // Grid
    private var gridController: MediaGridViewController?
    private var gridPreviousLeftNavItem: UIBarButtonItem?
    private var gridPreviousRightNavItem: UIBarButtonItem?
    
    // Appearance
    private var previousNavigationBarHidden = false
    private var previousNavigationBarTranslucent = false
    private var previousNavigationBarStyle = UIBarStyle.default
    private var previousNavigationBarTextColor: UIColor?
    private var previousNavigationBarBackgroundColor: UIColor?
    private var previousNavigationBarTintColor: UIColor?
    private var previousViewControllerBackButton: UIBarButtonItem?
    private var previousStatusBarStyle: UIStatusBarStyle = .lightContent
    
    // Video
    var currentVideoPlayerViewController: MPMoviePlayerViewController?
    var currentVideoIndex = 0
    var currentVideoLoadingIndicator: UIActivityIndicatorView?

    var activityViewController: UIActivityViewController?

    /// UINavigationBar Translucent for MediaBrowser
    public var navigationBarTranslucent = true
    
    /// UINavigationBar Text Color for MediaBrowser
    public var navigationBarTextColor = UIColor.white
    
    /// UINavigationBar Background Color for MediaBrowser
    public var navigationBarBackgroundColor = UIColor.black
    
    /// UINavigationBar Tint Color for MediaBrowser
    public var navigationBarTintColor = UIColor.black.withAlphaComponent(0.5)
    
    /// UIStatusBarStyle for MediaBrowser
    public var statusBarStyle: UIStatusBarStyle = .lightContent
    
    /// UIToolBar Text Color for MediaBrowser
    public var toolbarTextColor = UIColor.white
    
    /// UIToolBar Tint Color for MediaBrowser
    public var toolbarBarTintColor = UIColor.black.withAlphaComponent(0.5)
    
    /// UIToolBar Tint Background for MediaBrowser
    public var toolbarBackgroundColor = UIColor.black
    
    /// MediaBrowser has belonged to viewcontroller
    public var hasBelongedToViewController = false
    
    /// Check viewcontroller based status bar apperance
    public var isVCBasedStatusBarAppearance = false
    
    /// Hide or show status bar
    public var statusBarShouldBeHidden = false
    
    /// Display action button (share)
    public var displayActionButton = true
    
    /// Make status bar not hide
    public var leaveStatusBarAlone = false
    
    /// Perform layout
	public var performingLayout = false
    
    /// Support rotating
	public var rotating = false
    
    /// Active as in it's in the view heirarchy
    public var viewIsActive = false
    
    /// Save previous status bar style to return when push
    public var didSavePreviousStateOfNavBar = false
    
    /// Stop specific layout being triggered
    public var skipNextPagingScrollViewPositioning = false
    
    /// View has appeared initially
    public var viewHasAppearedInitially = false
    
    /// Make current grid offset
    public var currentGridContentOffset = CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude)
    
    /// Set MediaBrowserDelegate for MediaBrowser
    public var delegate: MediaBrowserDelegate?
    
    /// Available zoom photos to fill
    public var zoomPhotosToFill = true
    
    /// Display Media Navigation Arrows
    public var displayMediaNavigationArrows = false
    
    /// Display selection buttons
    public var displaySelectionButtons = false
    
    /// Always show controls
    public var alwaysShowControls = false
    
    /// Enable grid
    public var enableGrid = true
    
    /// Enable swipe to dismiss
    public var enableSwipeToDismiss = true
    
    /// Start on Grid
    public var startOnGrid = false
    
    /// Auto play video on appear
    public var autoPlayOnAppear = false
    
    /// Hide control when MediaBrowser start
    public var hideControlsOnStartup = false
    
    /// Hide time inerval
    public var delayToHideElements = TimeInterval(5.0)
    
    /// Captionview alpha
    public var captionAlpha = CGFloat(1)
    
    /// Toolbar alpha
    public var toolbarAlpha = CGFloat(1)
    
    /// Loading Indicator Inner Ring Color
    public var loadingIndicatorInnerRingColor = UIColor.white
    
    /// Loading Indicator Outer Ring Color
    public var loadingIndicatorOuterRingColor = UIColor.gray
    
    /// Loading Indicator Inner Ring Width
    public var loadingIndicatorInnerRingWidth:CGFloat = 1.0
    
    /// Loading Indicator Outer Ring Width
    public var loadingIndicatorOuterRingWidth:CGFloat = 1.0
    
    /// Loading Indicator Font
    public var loadingIndicatorFont = UIFont.systemFont(ofSize: 10)
    
    /// Loading Indicator Font Color
    public var loadingIndicatorFontColor = UIColor.white
    
    /// Loading Indicator Show or hide text
    public var loadingIndicatorShouldShowValueText = true
    
    /// Media selected on icon
    public var mediaSelectedOnIcon: UIImage?
    
    /// Media selected off icon
    public var mediaSelectedOffIcon: UIImage?
    
    /// Media selected grid on icon
    public var mediaSelectedGridOnIcon: UIImage?
    
    /// Media selected grid off icon
    public var mediaSelectedGridOffIcon: UIImage?
    
    /// Caching image count both side (e.g. when index 1, caching 0 and 2)
    public var cachingImageCount = 1
    
    //MARK: - Init
    
    /**
     init with delegate
     
     - Parameter nibName: nibName
     - Parameter nibBundle: nibBundle
     */
    public override init(nibName: String?, bundle nibBundle: Bundle?) {
        super.init(nibName: nibName, bundle: nibBundle)
        initialisation()
    }
    
    /**
     init with delegate
     
     - Parameter delegate: MediaBrowserDelegate
     */
    public convenience init(delegate: MediaBrowserDelegate) {
        self.init()
        self.delegate = delegate
    }

    /**
     init with media
     
     - Parameter media: Media array
     */
    public convenience init(media: [Media]) {
        self.init()
        fixedMediasArray = media
    }

    /**
     init with coder
     
     - Parameter coder: coder
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialisation()
    }
    
    private func initialisation() {
        // Defaults
        if let vcBasedStatusBarAppearance = Bundle.main.object(forInfoDictionaryKey: "UIViewControllerBasedStatusBarAppearance") as? Bool {
           isVCBasedStatusBarAppearance = vcBasedStatusBarAppearance
        } else {
            isVCBasedStatusBarAppearance = true
        }
        
        
        hidesBottomBarWhenPushed = true
        automaticallyAdjustsScrollViewInsets = false
//        extendedLayoutIncludesOpaqueBars = true
//        navigationController?.view.backgroundColor = UIColor.white
        
        // Listen for Media falsetifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePhotoLoadingDidEndNotification),
            name: NSNotification.Name(rawValue: MEDIA_LOADING_DID_END_NOTIFICATION),
            object: nil)
    }

    deinit {
        clearCurrentVideo()
        pagingScrollView.delegate = nil
        NotificationCenter.default.removeObserver(self)
        releaseAllUnderlyingPhotos(preserveCurrent: false)
        SDImageCache.shared().clearMemory() // clear memory
    }

    private func releaseAllUnderlyingPhotos(preserveCurrent: Bool) {
        // Create a copy in case this array is modified while we are looping through
        // Release photos
        var copy = mediaArray
        for p in copy {
            if let ph = p {
                if let paci = mediaAtIndex(index: currentIndex) {
                    if preserveCurrent && ph.equals(photo: paci) {
                        continue // skip current
                    }
                }
                
                ph.unloadUnderlyingImage()
            }
        }
        
        // Release thumbs
        copy = thumbMedias
        for p in copy {
            if let ph = p {
                ph.unloadUnderlyingImage()
            }
        }
    }
    /// didReceiveMemoryWarning
    public override func didReceiveMemoryWarning() {
        // Release any cached data, images, etc that aren't in use.
        releaseAllUnderlyingPhotos(preserveCurrent: true)
        recycledPages.removeAll(keepingCapacity: false)
        
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
    }

    //MARK: - View Loading

    /// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    public override func viewDidLoad() {
        // Validate grid settings
        if startOnGrid {
            enableGrid = true
        }
        
//        if enableGrid {
//            enableGrid = delegate?.thumbPhotoAtIndex(index: <#T##Int#>, MediaBrowser: <#T##MediaBrowser#>)
////            enableGrid = [delegate respondsToSelector:Selector("MediaBrowser:thumbPhotoAtIndex:)]
//        }
        
        if !enableGrid {
            startOnGrid = false
        }
        
        // View
        view.clipsToBounds = true
        
        // Setup paging scrolling view
        let pagingScrollViewFrame = frameForPagingScrollView
        pagingScrollView = UIScrollView(frame: pagingScrollViewFrame)
        pagingScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.black
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        view.addSubview(pagingScrollView)
        
        // Toolbar
        toolbar = UIToolbar(frame: frameForToolbar)
        toolbar.tintColor = toolbarTextColor
        toolbar.barTintColor = toolbarBarTintColor
        toolbar.backgroundColor = toolbarBackgroundColor
        toolbar.alpha = toolbarAlpha
        toolbar.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
        toolbar.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .compact)
        toolbar.barStyle = .default
        toolbar.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        
        // Toolbar Items
        if displayMediaNavigationArrows {
            let arrowPathFormat = "UIBarButtonItemArrow"
            
            let previousButtonImage = UIImage.imageForResourcePath(
                name: arrowPathFormat + "Left",
                inBundle: Bundle(for: MediaBrowser.self))
            
            let nextButtonImage = UIImage.imageForResourcePath(
                name: arrowPathFormat + "Right",
                inBundle: Bundle(for: MediaBrowser.self))
            
            previousButton = UIBarButtonItem(
                image: previousButtonImage,
                style: UIBarButtonItemStyle.plain,
                target: self,
                action: #selector(MediaBrowser.gotoPreviousPage))
            
            nextButton = UIBarButtonItem(
                image: nextButtonImage,
                style: UIBarButtonItemStyle.plain,
                target: self,
                action: #selector(MediaBrowser.gotoNextPage))
        }
        
        if displayActionButton {
            actionButton = UIBarButtonItem(
                barButtonSystemItem: UIBarButtonSystemItem.action,
                target: self,
                action: #selector(actionButtonPressed(_:)))
        }
        
        reloadData()
        
        if enableSwipeToDismiss {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(doneButtonPressed))
            swipeGesture.direction = [.down, .up]
            view.addGestureRecognizer(swipeGesture)
        }
        
        super.viewDidLoad()
    }
    
    /**
     view will transition
     
     - Parameter size: size
     - Parameter coordinator: UIViewControllerTransitionCoordinator
     */
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.toolbar.frame = self.frameForToolbar
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func performLayout() {
        // Setup
        performingLayout = true
        let photos = numberOfMedias
        
        // Setup pages
        visiblePages.removeAll()
        recycledPages.removeAll()
        
        // Navigation buttons
        if let navi = navigationController {
            if navi.viewControllers.count > 0 && navi.viewControllers[0] == self {
                // We're first on stack so show done button
                doneButton = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.done,
                    target: self,
                    action: #selector(doneButtonPressed))
                
                // Set appearance
                if let done = doneButton {
                    done.setBackgroundImage(nil, for: .normal, barMetrics: .default)
                    done.setBackgroundImage(nil, for: .highlighted, barMetrics: .compact)
                    
                    self.navigationItem.rightBarButtonItem = done
                }
            } else {
                // We're not first so show back button
                if let navi = navigationController, let previousViewController = navi.viewControllers[navi.viewControllers.count - 2] as? UINavigationController {
                    let backButtonTitle = previousViewController.navigationItem.backBarButtonItem != nil ?
                        previousViewController.navigationItem.backBarButtonItem!.title :
                        previousViewController.title
                    
                    let newBackButton = UIBarButtonItem(title: backButtonTitle, style: .plain, target: nil, action: nil)
                    
                    // Appearance
                    newBackButton.setBackButtonBackgroundImage(nil, for: .normal, barMetrics: .default)
                    newBackButton.setBackButtonBackgroundImage(nil, for: .highlighted, barMetrics: .compact)
//                    newBackButton.setTitleTextAttributes([String : AnyObject](), for: .normal)
//                    newBackButton.setTitleTextAttributes([String : AnyObject](), for: .highlighted)
                    
                    previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem // remember previous
                    previousViewController.navigationItem.backBarButtonItem = newBackButton
                }
            }
        }

        // Toolbar items
        var hasItems = false
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        fixedSpace.width = 32.0 // To balance action button
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        var items = [UIBarButtonItem]()
        
        // Left button - Grid
        if enableGrid {
            hasItems = true
            
            items.append(UIBarButtonItem(
                image: UIImage.imageForResourcePath(name: "UIBarButtonItemGrid", inBundle: Bundle(for: MediaBrowser.self)),
                style: .plain,
                target: self,
                action: #selector(MediaBrowser.showGridAnimated)))
        }
        else {
            items.append(fixedSpace)
        }

        // Middle - Nav
        if previousButton != nil && nextButton != nil && photos > 1 {
            hasItems = true
            
            items.append(flexSpace)
            items.append(previousButton!)
            items.append(flexSpace)
            items.append(nextButton!)
            items.append(flexSpace)
        }
        else {
            items.append(flexSpace)
        }

        // Right - Action
        if actionButton != nil && !(!hasItems && nil == navigationItem.rightBarButtonItem) {
            items.append(actionButton!)
        }
        else {
            // We're falset showing the toolbar so try and show in top right
            if actionButton != nil {
                navigationItem.rightBarButtonItem = actionButton!
            }
            items.append(fixedSpace)
        }

        // Toolbar visibility
        toolbar.setItems(items, animated: false)
        var hideToolbar = true
        
        for item in items {
            if item != fixedSpace && item != flexSpace {
                hideToolbar = false
                break
            }
        }
        
        if hideToolbar {
            toolbar.removeFromSuperview()
        }
        else {
            view.addSubview(toolbar)
        }
        
        // Update nav
        updateNavigation()
        
        // Content offset
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(index: currentPageIndex)
        tilePages()
        performingLayout = false
    }

    var presentingViewControllerPrefersStatusBarHidden: Bool {
        var presenting = presentingViewController
        if let p = presenting as? UINavigationController {
            presenting = p.topViewController
        }
        else {
            // We're in a navigation controller so get previous one!
            if let navi = navigationController, navi.viewControllers.count > 1 {
                presenting = navi.viewControllers[navi.viewControllers.count - 2]
            }
        }
        
        if let pres = presenting {
            return pres.prefersStatusBarHidden
        }
        
        return false
    }

    //MARK: - Appearance

    /**
     viewWillAppear
     
     - Parameter animated: Bool
     */
    public override func viewWillAppear(_ animated: Bool) {
        // Super
        super.viewWillAppear(animated)
        
        // Status bar
        if !viewHasAppearedInitially {
            leaveStatusBarAlone = presentingViewControllerPrefersStatusBarHidden
            // Check if status bar is hidden on first appear, and if so then ignore it
            if UIApplication.shared.statusBarFrame.equalTo(CGRect.zero) {
                leaveStatusBarAlone = true
            }
        }
        
        // Navigation bar appearance
        if !viewIsActive && navigationController?.viewControllers[0] as? MediaBrowser !== self {
            storePreviousNavBarAppearance()
        }
        
        // Set style
        if !leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            previousStatusBarStyle = UIApplication.shared.statusBarStyle
            UIApplication.shared.setStatusBarStyle(statusBarStyle, animated: animated)
        }

        setNavBarAppearance(animated: animated)
        
        // Update UI
        if hideControlsOnStartup {
            hideControls()
        }
        else {
            hideControlsAfterDelay()
        }
        
        // Initial appearance
        if !viewHasAppearedInitially && startOnGrid {
            showGrid(animated: false)
        }
        
        // If rotation occured while we're presenting a modal
        // and the index changed, make sure we show the right one falsew
        if currentPageIndex != pageIndexBeforeRotation {
            jumpToPageAtIndex(index: pageIndexBeforeRotation, animated: false)
        }
        
        self.view.setNeedsLayout()
    }

    /**
     view Did Appear
     
     - Parameter animated: Bool
     */
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewIsActive = true
        
        // Autoplay if first is video
        if !viewHasAppearedInitially && autoPlayOnAppear {
            if let photo = mediaAtIndex(index: currentPageIndex) {
                if photo.isVideo {
                    playVideoAtIndex(index: currentPageIndex)
                }
            }
        }
        
        viewHasAppearedInitially = true
    }

    /**
     view will disappear
     
     - Parameter animated: Bool
     */
    public override func viewWillDisappear(_ animated: Bool) {
        // Detect if rotation occurs while we're presenting a modal
        pageIndexBeforeRotation = currentPageIndex
        
        // Check that we're being popped for good
        if let viewControllers = navigationController?.viewControllers, viewControllers[0] !== self {
            var selfFound = false
        
            for vc in viewControllers {
                if vc === self {
                    selfFound = true
                    break;
                }
            }
            
            if !selfFound {
                // State
                viewIsActive = false
                
                // Bar state / appearance
                restorePreviousNavBarAppearance(animated: animated)
            }
        }
        
        // Controls
        navigationController?.navigationBar.layer.removeAllAnimations() // Stop all animations on nav bar
        
        NSObject.cancelPreviousPerformRequests(withTarget: self) // Cancel any pending toggles from taps
        setControlsHidden(hidden: false, animated: false, permanent: true)
        
        // Status bar
        if !leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            UIApplication.shared.setStatusBarStyle(previousStatusBarStyle, animated: animated)
        }

        // Super
        super.viewWillDisappear(animated)
    }

    /**
     will move toParentViewController
     
     - Parameter parent: UIViewController
     */
    public override func willMove(toParentViewController parent: UIViewController?) {
        if parent != nil && hasBelongedToViewController {
            fatalError("MediaBrowser Instance Reuse")
        }
    }
    
    /**
     did move toParentViewController
     
     - Parameter parent: UIViewController
     */
    public override func didMove(toParentViewController parent: UIViewController?) {
        if nil == parent {
            hasBelongedToViewController = true
        }

    }

    //MARK: - Nav Bar Appearance
    func setNavBarAppearance(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
    
        if let navBar = navigationController?.navigationBar {
            navBar.titleTextAttributes = [NSForegroundColorAttributeName:navigationBarTextColor]
            navBar.backgroundColor = navigationBarBackgroundColor
            navBar.tintColor = navigationBarTextColor
            navBar.barTintColor = navigationBarTintColor
            navBar.shadowImage = nil
            navBar.isTranslucent = navigationBarTranslucent
            navBar.barStyle = .black
        }
    }

    func storePreviousNavBarAppearance() {
        didSavePreviousStateOfNavBar = true
        
        if let navi = navigationController {
            previousNavigationBarTintColor = navi.navigationBar.barTintColor
            previousNavigationBarBackgroundColor = navi.navigationBar.backgroundColor
            previousNavigationBarTranslucent = navi.navigationBar.isTranslucent
            previousNavigationBarTextColor = navi.navigationBar.tintColor
            previousNavigationBarHidden = navi.isNavigationBarHidden
            previousNavigationBarStyle = navi.navigationBar.barStyle
        }
    }

    func restorePreviousNavBarAppearance(animated: Bool) {
        if let navi = navigationController, didSavePreviousStateOfNavBar {
            navi.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
            
            let navBar = navi.navigationBar
            navBar.titleTextAttributes = [NSForegroundColorAttributeName:previousNavigationBarTextColor ?? UIColor.black]
            navBar.backgroundColor = previousNavigationBarBackgroundColor
            navBar.tintColor = previousNavigationBarTextColor
            navBar.isTranslucent = previousNavigationBarTranslucent
            navBar.barTintColor = previousNavigationBarTintColor
            navBar.barStyle = previousNavigationBarStyle

            // Restore back button if we need to
            if previousViewControllerBackButton != nil {
                if let previousViewController = navi.topViewController { // We've disappeared so previous is falsew top
                    previousViewController.navigationItem.backBarButtonItem = previousViewControllerBackButton
                }
                previousViewControllerBackButton = nil
            }
        }
    }

    //MARK: - Layout
    /// viewWillLayoutSubviews
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutVisiblePages()
    }

    func layoutVisiblePages() {
        // Flag
        performingLayout = true
        
        // Toolbar
        toolbar.frame = frameForToolbar
        
        // Remember index
        let indexPriorToLayout = currentPageIndex
        
        // Get paging scroll view frame to determine if anything needs changing
        let pagingScrollViewFrame = frameForPagingScrollView
        
        // Frame needs changing
        if !skipNextPagingScrollViewPositioning {
            pagingScrollView.frame = pagingScrollViewFrame
        }
        
        skipNextPagingScrollViewPositioning = false
        
        // Recalculate contentSize based on current orientation
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        
        // Adjust frames and configuration of each visible page
        for page in visiblePages {
            let index = page.index
            page.frame = frameForPageAtIndex(index: index)
            
            if let caption = page.captionView {
                caption.frame = frameForCaptionView(captionView: caption, index: index)
            }
            
            if let selected = page.selectedButton {
                selected.frame = frameForSelectedButton(selectedButton: selected, atIndex: index)
            }
            
            if let play = page.playButton {
                play.frame = frameForPlayButton(playButton: play, atIndex: index)
            }
            
            // Adjust scales if bounds has changed since last time
            if !previousLayoutBounds.equalTo(view.bounds) {
                // Update zooms for new bounds
                page.setMaxMinZoomScalesForCurrentBounds()
                previousLayoutBounds = view.bounds
            }
        }
        
        // Adjust video loading indicator if it's visible
        positionVideoLoadingIndicator()
        
        // Adjust contentOffset to preserve page location based on values collected prior to location
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(index: indexPriorToLayout)
        didStartViewingPageAtIndex(index: currentPageIndex) // initial
        
        // Reset
        currentPageIndex = indexPriorToLayout
        performingLayout = false
        
    }

    //MARK: - Rotation
    /// supported interface orientations
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// will rotate to interfaceOrientation
    public override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        // Remember page index before rotation
        pageIndexBeforeRotation = currentPageIndex
        rotating = true
        
        // In iOS 7 the nav bar gets shown after rotation, but might as well do this for everything!
        if areControlsHidden {
            // Force hidden
            navigationController?.isNavigationBarHidden = true
        }
    }
    
    /// will animate rotation
    public override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        // Perform layout
        currentPageIndex = pageIndexBeforeRotation
        
        // Delay control holding
        hideControlsAfterDelay()
        
        // Layout
        layoutVisiblePages()
    }
    
    /// did rotate
    public override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        rotating = false
        // Ensure nav bar isn't re-displayed
        if let navi = navigationController, areControlsHidden {
            navi.isNavigationBarHidden = false
            navi.navigationBar.alpha = 0
        }
    }

    //MARK: - Data

    var currentIndex: Int {
        return currentPageIndex
    }

    func reloadData() {
        // Reset
        mediaCount = -1
        
        // Get data
        let photosNum = numberOfMedias
        releaseAllUnderlyingPhotos(preserveCurrent: true)
        mediaArray.removeAll()
        thumbMedias.removeAll()
        
        for _ in 0...(photosNum - 1) {
            mediaArray.append(nil)
            thumbMedias.append(nil)
        }

        // Update current page index
        if numberOfMedias > 0 {
            currentPageIndex = max(0, min(currentPageIndex, photosNum - 1))
        }
        else {
            currentPageIndex = 0
        }
        
        // Update layout
        if isViewLoaded {
            while pagingScrollView.subviews.count > 0 {
                pagingScrollView.subviews.last!.removeFromSuperview()
            }
            
            performLayout()
            view.setNeedsLayout()
        }
    }

    var numberOfMedias: Int {
        if mediaCount == -1 {
            if let d = delegate {
                mediaCount = d.numberOfMedia(in: self)
            }
            
            if let fpa = fixedMediasArray {
                mediaCount = fpa.count
            }
        }
        
        if -1 == mediaCount {
            mediaCount = 0
        }

        return mediaCount
    }

    func mediaAtIndex(index: Int) -> Media? {
        var photo: Media? = nil
        
        if index < mediaArray.count {
            if mediaArray[index] == nil {
                if let d = delegate {
                    photo = d.media(for: self, at: index)
                    
                    if nil == photo && fixedMediasArray != nil && index < fixedMediasArray!.count {
                        photo = fixedMediasArray![index]
                    }
                    
                    if photo != nil {
                        mediaArray[index] = photo
                    }
                }
            }
            else {
                photo = mediaArray[index]
            }
        }
        
        return photo
    }

    func thumbPhotoAtIndex(index: Int) -> Media? {
        var photo: Media?
        
        if index < thumbMedias.count {
            if nil == thumbMedias[index] {
                if let d = delegate {
                    photo = d.thumbnail(for: self, at: index)
                
                    if let p = photo {
                        thumbMedias[index] = p
                    }
                }
            }
            else {
                photo = thumbMedias[index]
            }
        }
        
        return photo
    }

    func captionViewForPhotoAtIndex(index: Int) -> MediaCaptionView? {
        var captionView: MediaCaptionView?
        
        if let d = delegate {
            captionView = d.captionView(for: self, at: index)
            
            if let p = mediaAtIndex(index: index), nil == captionView {
                if p.caption.characters.count > 0 {
                    captionView = MediaCaptionView(media: p)
                }
            }
        }
        
        if let cv = captionView {
            cv.alpha = areControlsHidden ? 0.0 : captionAlpha // Initial alpha
        }
        
        return captionView
    }

    func photoIsSelectedAtIndex(index: Int) -> Bool {
        var value = false
        if displaySelectionButtons {
            if let d = delegate {
                value = d.isMediaSelected(at: index, in: self)
            }
        }
        
        return value
    }

    func setPhotoSelected(selected: Bool, atIndex index: Int) {
        if displaySelectionButtons {
            if let d = delegate {
                d.mediaDid(selected: selected, at: index, in: self)
            }
        }
    }

    func imageForPhoto(photo: Media?) -> UIImage? {
        if let p = photo {
            // Get image or obtain in background
            if let img = p.underlyingImage {
                return img
            }
            else {
                p.loadUnderlyingImageAndNotify()
            }
        }
        
        return nil
    }

    func loadAdjacentPhotosIfNecessary(photo: Media) {
        let page = pageDisplayingPhoto(photo: photo)
        if let p = page {
            // If page is current page then initiate loading of previous and next pages
            let pageIndex = p.index
            if currentPageIndex == pageIndex {
                if pageIndex > 0  && mediaArray.count >= cachingImageCount {
                    // Preload index - 1
                    if let photo = mediaAtIndex(index: pageIndex - 1) {
                        if nil == photo.underlyingImage {
                            photo.loadUnderlyingImageAndNotify()
//                            print("Pre-loading image at index \(pageIndex-1)")
                        }
                    }
                }
                
                if pageIndex < numberOfMedias - 1 {
                    // Preload index + 1
                    if let photo = mediaAtIndex(index: pageIndex + 1) {
                        if nil == photo.underlyingImage {
                            photo.loadUnderlyingImageAndNotify()
//                            print("Pre-loading image at index \(pageIndex+1)")
                        }
                    }
                }
            }
        }
    }

    //MARK: - Media Loading falsetification
    func handlePhotoLoadingDidEndNotification(notification: NSNotification) {
        if let photo = notification.object as? Media {
            if let page = pageDisplayingPhoto(photo: photo) {
                if photo.underlyingImage != nil {
                    // Successful load
                    page.displayImage()
                    loadAdjacentPhotosIfNecessary(photo: photo)
                }
                else {
                    // Failed to load
                    page.displayImageFailure()
                }
                // Update nav
                updateNavigation()
            }
        }
    }

    //MARK: - Paging

    func tilePages() {
        // Calculate which pages should be visible
        // Ignore padding as paging bounces encroach on that
        // and lead to false page loads
        let visibleBounds = pagingScrollView.bounds
        var iFirstIndex = Int(floorf(Float((visibleBounds.minX + padding * 2.0) / visibleBounds.width)))
        var iLastIndex  = Int(floorf(Float((visibleBounds.maxX - padding * 2.0 - 1.0) / visibleBounds.width)))
        
        if iFirstIndex < 0 {
            iFirstIndex = 0
        }
        
        if iFirstIndex > numberOfMedias - 1 {
            iFirstIndex = numberOfMedias - 1
        }
        
        if iLastIndex < 0 {
            iLastIndex = 0
        }
        
        if iLastIndex > numberOfMedias - 1 {
            iLastIndex = numberOfMedias - 1
        }
        
        // Recycle false longer needed pages
        var pageIndex = 0
        for page in visiblePages {
            pageIndex = page.index
            
            if pageIndex < iFirstIndex || pageIndex > iLastIndex {
                recycledPages.insert(page)
                
                if let cw = page.captionView {
                    cw.removeFromSuperview()
                }
                
                if let selected = page.selectedButton {
                    selected.removeFromSuperview()
                }
                
                if let play = page.playButton {
                    play.removeFromSuperview()
                }
                
                page.prepareForReuse()
                page.removeFromSuperview()
                
                //MWLog(@"Removed page at index %lu", (unsigned long)pageIndex)
            }
        }
        // 확인 필요!
        visiblePages = visiblePages.subtracting(recycledPages)
        
        while recycledPages.count > 2 { // Only keep 2 recycled pages
            recycledPages.remove(recycledPages.first!)
        }
        
        // Add missing pages
        for index in iFirstIndex...iLastIndex {
            if !isDisplayingPageForIndex(index: index) {
                // Add new page
                var p = dequeueRecycledPage
                if nil == p {
                    p = MediaZoomingScrollView(mediaBrowser: self)
                }
                
                let page = p!
                
                page.loadingIndicator.innerRingColor = loadingIndicatorInnerRingColor
                page.loadingIndicator.outerRingColor = loadingIndicatorOuterRingColor
                page.loadingIndicator.innerRingWidth = loadingIndicatorInnerRingWidth
                page.loadingIndicator.outerRingWidth = loadingIndicatorOuterRingWidth
                page.loadingIndicator.font = loadingIndicatorFont
                page.loadingIndicator.fontColor = loadingIndicatorFontColor
                page.loadingIndicator.shouldShowValueText = loadingIndicatorShouldShowValueText
                
                visiblePages.insert(page)
                configurePage(page: page, forIndex: index)

                pagingScrollView.addSubview(page)
                
                // Add caption
                if let captionView = captionViewForPhotoAtIndex(index: index) {
                    captionView.frame = frameForCaptionView(captionView: captionView, index: index)
                    pagingScrollView.addSubview(captionView)
                    page.captionView = captionView
                }
                
                // Add play button if needed
                if page.displayingVideo() {
                    let playButton = UIButton(type: .custom)
                    playButton.setImage(UIImage(named: "PlayButtonOverlayLarge", in: Bundle(for: MediaBrowser.self), compatibleWith: nil), for: .normal)
                    playButton.setImage(UIImage(named: "PlayButtonOverlayLargeTap", in: Bundle(for: MediaBrowser.self), compatibleWith: nil), for: .highlighted)
                    playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
                    playButton.sizeToFit()
                    playButton.frame = frameForPlayButton(playButton: playButton, atIndex: index)
                    pagingScrollView.addSubview(playButton)
                    page.playButton = playButton
                }
                
                // Add selected button
                if self.displaySelectionButtons {
                    let selectedButton = UIButton(type: .custom)
                    if let selectedOffImage = mediaSelectedOffIcon {
                        selectedButton.setImage(selectedOffImage, for: .normal)
                    } else {
                        selectedButton.setImage(UIImage(named: "ImageSelectedSmallOff", in: Bundle(for: MediaBrowser.self), compatibleWith: nil), for: .normal)
                    }
                    
                    if let selectedOnImage = mediaSelectedOnIcon {
                        selectedButton.setImage(selectedOnImage, for: .selected)
                    } else {
                        selectedButton.setImage(UIImage(named: "ImageSelectedSmallOn", in: Bundle(for: MediaBrowser.self), compatibleWith: nil), for: .selected)
                    }

                    selectedButton.sizeToFit()
                    selectedButton.adjustsImageWhenHighlighted = false
                    selectedButton.addTarget(self, action: #selector(selectedButtonTapped), for: .touchUpInside)
                    selectedButton.frame = frameForSelectedButton(selectedButton: selectedButton, atIndex: index)
                    pagingScrollView.addSubview(selectedButton)
                    page.selectedButton = selectedButton
                    selectedButton.isSelected = photoIsSelectedAtIndex(index: index)
                }
            }
        }
    }

    func updateVisiblePageStates() {
        let copy = visiblePages
        for page in copy {
            // Update selection
            if let selected = page.selectedButton {
                selected.isSelected = photoIsSelectedAtIndex(index: page.index)
            }
        }
    }

    func isDisplayingPageForIndex(index: Int) -> Bool {
        for page in visiblePages {
            if page.index == index {
                return true
            }
        }
    
        return false
    }

    func pageDisplayedAtIndex(index: Int) -> MediaZoomingScrollView? {
        var thePage: MediaZoomingScrollView?
        for page in visiblePages {
            if page.index == index {
                thePage = page
                break
            }
        }
        return thePage
    }

    func pageDisplayingPhoto(photo: Media) -> MediaZoomingScrollView? {
        var thePage: MediaZoomingScrollView?
        for page in visiblePages {
            if page.photo != nil && page.photo!.equals(photo: photo) {
                thePage = page
                break
            }
        }
        return thePage
    }

    func configurePage(page: MediaZoomingScrollView, forIndex index: Int) {
        page.frame = frameForPageAtIndex(index: index)
        page.index = index
        page.photo = mediaAtIndex(index: index)
//        page.backgroundColor = areControlsHidden ? UIColor.black : UIColor.white
    }

    var dequeueRecycledPage: MediaZoomingScrollView? {
        let page = recycledPages.first
        if let p = page {
            recycledPages.remove(p)
        }
        return page
    }

    // Handle page changes
    func didStartViewingPageAtIndex(index: Int) {
        // Handle 0 photos
        if 0 == numberOfMedias {
            // Show controls
            setControlsHidden(hidden: false, animated: true, permanent: true)
            return
        }
        
        // Handle video on page change
        if !rotating || index != currentVideoIndex {
            clearCurrentVideo()
        }
        
        // Release images further away than +/-1
        if index > 0 {
            // Release anything < index - 1
            if index - 2 >= 0 {
                for i in 0...(index - 2) {
                    if let media = mediaArray[i] {
                        media.unloadUnderlyingImage()
                        mediaArray[i] = nil
                        
                        //MWLog.log("Released underlying image at index \(i)")
                    }
                }
            }
        }
        
        if index < numberOfMedias - 1 {
            // Release anything > index + 1
            if index + 2 <= mediaArray.count - 1 {
                for i in (index + 2)...(mediaArray.count - 1) {
                    if let media = mediaArray[i] {
                        media.unloadUnderlyingImage()
                        mediaArray[i] = nil
                    
                        //MWLog.log("Released underlying image at index \(i)")
                    }
                }
            }
        }
        
        // Load adjacent images if needed and the photo is already
        // loaded. Also called after photo has been loaded in background
        let currentPhoto = mediaAtIndex(index: index)
        
        if let cp = currentPhoto {
            if cp.underlyingImage != nil {
                // photo loaded so load ajacent falsew
                loadAdjacentPhotosIfNecessary(photo: cp)
            }
        }
        
        // Notify delegate
        if index != previousPageIndex {
            if let d = delegate {
                d.didDisplayMedia(at: index, in: self)
            }
            previousPageIndex = index
        }
        
        // Update nav
        updateNavigation()
    }

    //MARK: - Frame Calculations

    var frameForPagingScrollView: CGRect {
        var frame = view.bounds// UIScreen.mainScreen().bounds
        frame.origin.x -= padding
        frame.size.width += (2.0 * padding)
        return frame.integral
    }

    func frameForPageAtIndex(index: Int) -> CGRect {
        // We have to use our paging scroll view's bounds, falset frame, to calculate the page placement. When the device is in
        // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
        // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
        // because it has a rotation transform applied.
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2.0 * padding)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + padding
        return pageFrame.integral
    }

    func contentSizeForPagingScrollView() -> CGSize {
        // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
        let bounds = pagingScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfMedias), height: bounds.size.height)
    }

    func contentOffsetForPageAtIndex(index: Int) -> CGPoint {
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPoint(x: newOffset, y: 0)
    }

    var frameForToolbar: CGRect {
        var height = CGFloat(44.0)
        
        if view.bounds.height < 768.0 && view.bounds.height < view.bounds.width {
            height = 32.0
        }
        
        return CGRect(x: 0.0, y: view.bounds.size.height - height, width: view.bounds.size.width, height: height).integral
    }

    func frameForCaptionView(captionView: MediaCaptionView?, index: Int) -> CGRect {
        if let cw = captionView {
            let pageFrame = frameForPageAtIndex(index: index)
            let captionSize = cw.sizeThatFits(CGSize(width: pageFrame.size.width, height: 0.0))
            let captionFrame = CGRect(
                x: pageFrame.origin.x,
                y: pageFrame.size.height - captionSize.height - (toolbar.superview != nil ? toolbar.frame.size.height : 0.0),
                width: pageFrame.size.width,
                height: captionSize.height)
            
            return captionFrame.integral
        }
        
        return CGRect.zero
    }

    func frameForSelectedButton(selectedButton: UIButton, atIndex index: Int) -> CGRect {
        let pageFrame = frameForPageAtIndex(index: index)
        let padding = CGFloat(20.0)
        var yOffset = CGFloat(0.0)
        
        if !areControlsHidden {
            if let navBar = navigationController?.navigationBar {
                yOffset = navBar.frame.origin.y + navBar.frame.size.height
            }
        }
        
        let selectedButtonFrame = CGRect(
            x: pageFrame.origin.x + pageFrame.size.width - selectedButton.frame.size.width - padding,
            y: padding + yOffset,
            width: selectedButton.frame.size.width,
            height: selectedButton.frame.size.height)
        
        return selectedButtonFrame.integral
    }

    func frameForPlayButton(playButton: UIButton, atIndex index: Int) -> CGRect {
        let pageFrame = frameForPageAtIndex(index: index)
        return CGRect(
            x: CGFloat(floorf(Float(pageFrame.midX - playButton.frame.size.width / 2.0))),
            y: CGFloat(floorf(Float(pageFrame.midY - playButton.frame.size.height / 2.0))),
            width: playButton.frame.size.width,
            height: playButton.frame.size.height)
    }

    //MARK: - UIScrollView Delegate
    /// UIScrollViewDelegate - scrollViewDidScroll
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Checks
        if !viewIsActive || performingLayout || rotating {
            return
        }
        
        // Tile pages
        tilePages()
        
        // Calculate current page
        let visibleBounds = pagingScrollView.bounds
        var index = Int(floorf(Float(visibleBounds.midX / visibleBounds.width)))
        if index < 0 {
            index = 0
        }
        
        if index > numberOfMedias - 1 {
            index = numberOfMedias - 1
        }
        
        let previousCurrentPage = currentPageIndex
        currentPageIndex = index
        
        if currentPageIndex != previousCurrentPage {
            didStartViewingPageAtIndex(index: index)
        }
    }

    /// UIScrollViewDelegate - scrollViewWillBeginDragging
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Hide controls when dragging begins
        setControlsHidden(hidden: true, animated: true, permanent: false)
    }

    /// UIScrollViewDelegate - scrollViewDidEndDecelerating
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update nav when page changes
        updateNavigation()
    }

    //MARK: - Navigation

    func updateNavigation() {
        // Title
        let medias = numberOfMedias
        if let gc = gridController {
            if gc.selectionMode {
                self.title = NSLocalizedString("Select Photos", comment: "")
            }
            else {
                let photosText: String
                
                if 1 == medias {
                    photosText = NSLocalizedString("photo", comment: "Used in the context: '1 photo'")
                }
                else {
                    photosText = NSLocalizedString("photos", comment: "Used in the context: '3 photos'")
                }
                
                title = "\(medias) \(photosText)"
            }
        }
        else
        if medias > 1 {
            if let d = delegate {
                title = d.title(for: self, at: currentPageIndex)
            }
            
            if nil == title {
                let str = NSLocalizedString("of", comment: "Used in the context: 'Showing 1 of 3 items'")
                title = "\(currentPageIndex + 1) \(str) \(numberOfMedias)"
            }
        }
        else {
            title = nil
        }
        
        // Buttons
        if let prev = previousButton {
            prev.isEnabled = (currentPageIndex > 0)
        }
        
        if let next = nextButton {
            next.isEnabled = (currentPageIndex < medias - 1)
        }
        
        // Disable action button if there is false image or it's a video
        if let ab = actionButton {
            let photo = mediaAtIndex(index: currentPageIndex)

            if photo != nil && (photo!.underlyingImage == nil || photo!.isVideo) {
                ab.isEnabled = false
                ab.tintColor = UIColor.clear // Tint to hide button
            }
            else {
                ab.isEnabled = true
                ab.tintColor = nil
            }
        }
    }

    func jumpToPageAtIndex(index: Int, animated: Bool) {
        // Change page
        if index < numberOfMedias {
            let pageFrame = frameForPageAtIndex(index: index)
            pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - padding, y: 0), animated: animated)
            updateNavigation()
        }
        
        // Update timer to give more time
        hideControlsAfterDelay()
    }

    func gotoPreviousPage() {
        showPreviousPhotoAnimated(animated: false)
    }
    func gotoNextPage() {
        showNextPhotoAnimated(animated: false)
    }

    func showPreviousPhotoAnimated(animated: Bool) {
        jumpToPageAtIndex(index: currentPageIndex - 1, animated: animated)
    }

    func showNextPhotoAnimated(animated: Bool) {
        jumpToPageAtIndex(index: currentPageIndex + 1, animated: animated)
    }

    //MARK: - Interactions

    func selectedButtonTapped(sender: UIButton) {
        sender.isSelected = !sender.isSelected
    
        var index = Int.max
        for page in visiblePages {
            if page.selectedButton == sender {
                index = page.index
                break
            }
        }
    
        if index != Int.max {
            setPhotoSelected(selected: sender.isSelected, atIndex: index)
        }
    }

    func playButtonTapped(sender: UIButton) {
        var index = Int.max
    
        for page in visiblePages {
            if page.playButton == sender {
                index = page.index
                break
            }
        }
        
        if index != Int.max {
            if nil == currentVideoPlayerViewController {
                playVideoAtIndex(index: index)
            }
        }
    }

    //MARK: - Video

    func playVideoAtIndex(index: Int) {
        let photo = mediaAtIndex(index: index)
        
        // Valid for playing
        currentVideoIndex = index
        clearCurrentVideo()
        setVideoLoadingIndicatorVisible(visible: true, atPageIndex: index)
        
        // Get video and play
        if let p = photo {
            p.getVideoURL() { url in
                if let u = url {
                    DispatchQueue.main.async() {
                        self.playVideo(videoURL: u, atPhotoIndex: index)
                    }
                }
                else {
                    self.setVideoLoadingIndicatorVisible(visible: false, atPageIndex: index)
                }
            }
        }
    }

    func playVideo(videoURL: URL, atPhotoIndex index: Int) {
        // Setup player
        currentVideoPlayerViewController = MPMoviePlayerViewController(contentURL: videoURL as URL!)
        
        if let player = currentVideoPlayerViewController {
            player.moviePlayer.prepareToPlay()
            player.moviePlayer.shouldAutoplay = true
            player.moviePlayer.scalingMode = .aspectFit
            player.modalTransitionStyle = .crossDissolve
        
            // Remove the movie player view controller from the "playback did finish" falsetification observers
            // Observe ourselves so we can get it to use the crossfade transition
            NotificationCenter.default.removeObserver(
                player,
                name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish,
                object: player.moviePlayer)
        
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoFinishedCallback),
                name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish,
                object: player.moviePlayer)

            // Show
            present(player, animated: true, completion: nil)
        }
    }

    func videoFinishedCallback(notification: NSNotification) {
        if let player = currentVideoPlayerViewController {
            // Remove observer
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish,
                object: player.moviePlayer)
            
            // Clear up
            clearCurrentVideo()
            
            // Dismiss
            if let errorObj = notification.userInfo?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] {
                let error = MPMovieFinishReason(rawValue: errorObj as! Int)
            
                if error == .playbackError {
                    // Error occured so dismiss with a delay incase error was immediate and we need to wait to dismiss the VC

                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(1.0 * Double(NSEC_PER_SEC)), execute: {
                        self.dismiss(animated: true, completion: nil)

                    })
                    
                    return
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
    }

    func clearCurrentVideo() {
        if currentVideoPlayerViewController != nil {
            currentVideoLoadingIndicator?.removeFromSuperview()
            currentVideoPlayerViewController = nil
            currentVideoLoadingIndicator = nil
            currentVideoIndex = Int.max
        }
    }

    func setVideoLoadingIndicatorVisible(visible: Bool, atPageIndex: Int) {
        if currentVideoLoadingIndicator != nil && !visible {
            currentVideoLoadingIndicator?.removeFromSuperview()
            currentVideoLoadingIndicator = nil
        } else if currentVideoLoadingIndicator == nil && visible {
            currentVideoLoadingIndicator = UIActivityIndicatorView(frame: CGRect.zero)
            currentVideoLoadingIndicator?.sizeToFit()
            currentVideoLoadingIndicator?.startAnimating()
            pagingScrollView.addSubview(currentVideoLoadingIndicator!)
            
            positionVideoLoadingIndicator()
        }
    }

    func positionVideoLoadingIndicator() {
        if currentVideoLoadingIndicator != nil && currentVideoIndex != Int.max {
            let frame = frameForPageAtIndex(index: currentVideoIndex)
            currentVideoLoadingIndicator!.center = CGPoint(x: frame.midX, y: frame.midY)
        }
    }

    //MARK: - Grid

    func showGridAnimated() {
        showGrid(animated: true)
    }

    func showGrid(animated: Bool) {
        if gridController != nil {
            return
        }
        
        // Init grid controller
        gridController = MediaGridViewController()
        
        if let gc = gridController, let navBar = navigationController?.navigationBar {
            let bounds = view.bounds
            let naviHeight = navBar.frame.height + UIApplication.shared.statusBarFrame.height
            
            gc.initialContentOffset = currentGridContentOffset
            gc.browser = self
            gc.selectionMode = displaySelectionButtons
            gc.view.frame = CGRect(x: 0.0, y: naviHeight, width: bounds.width, height: bounds.height - naviHeight)
            gc.view.alpha = 0.0
            
            // Stop specific layout being triggered
            skipNextPagingScrollViewPositioning = true
            
            // Add as a child view controller
            addChildViewController(gc)
            view.addSubview(gc.view)
        
            // Perform any adjustments
            gc.view.layoutIfNeeded()
            gc.adjustOffsetsAsRequired()
        
            // Hide action button on nav bar if it exists
            if navigationItem.rightBarButtonItem == actionButton {
                gridPreviousRightNavItem = actionButton
                navigationItem.setRightBarButton(nil, animated: true)
            }
            else {
                gridPreviousRightNavItem = nil
            }
            
            // Update
            updateNavigation()
            setControlsHidden(hidden: false, animated: true, permanent: true)
            
            // Animate grid in and photo scroller out
            gc.willMove(toParentViewController: self)
            UIView.animate(
                withDuration: animated ? 0.3 : 0,
                animations: {
                    gc.view.alpha = 1.0
                    self.pagingScrollView.alpha = 0.0
                },
                completion: { finished in
                    gc.didMove(toParentViewController: self)
                })
        }
    }

    func hideGrid() {
        if let gc = gridController {
            // Remember previous content offset
            currentGridContentOffset = gc.collectionView!.contentOffset
            
            // Restore action button if it was removed
            if gridPreviousRightNavItem == actionButton && actionButton != nil {
                navigationItem.setRightBarButton(gridPreviousRightNavItem, animated: true)
            }
            
            // Position prior to hide animation
            let pagingFrame = frameForPagingScrollView
            pagingScrollView.frame = pagingFrame.offsetBy(
                dx: 0,
                dy: (self.startOnGrid ? 1 : -1) * pagingFrame.size.height)
            
            // Remember and remove controller now so things can detect a nil grid controller
            gridController = nil
            
            // Update
            updateNavigation()
            updateVisiblePageStates()
            view.layoutIfNeeded()
            view.layoutSubviews()
            
            self.pagingScrollView.frame = self.frameForPagingScrollView
            
            // Animate, hide grid and show paging scroll view
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    gc.view.alpha = 0.0
                    self.pagingScrollView.alpha = 1.0
                },
                completion: { finished in
                    gc.willMove(toParentViewController: nil)
                    gc.view.removeFromSuperview()
                    gc.removeFromParentViewController()
            
                    self.setControlsHidden(hidden: false, animated: true, permanent: false) // retrigger timer
                })
        }
    }

    //MARK: - Control Hiding / Showing

    // If permanent then we don't set timers to hide again
    func setControlsHidden( hidden: Bool, animated: Bool, permanent: Bool) {
        // Force visible
        var hidden = hidden
        if 0 == numberOfMedias || gridController != nil || alwaysShowControls {
            hidden = false
        }
        
        // Cancel any timers
        cancelControlHiding()
        
        // Animations & positions
        let animatonOffset = CGFloat(20)
        let animationDuration = CFTimeInterval(animated ? 0.35 : 0.0)
        
        // Status bar
        if !leaveStatusBarAlone {
            // Hide status bar
            if !isVCBasedStatusBarAppearance {
                // falsen-view controller based
                statusBarShouldBeHidden = hidden
                UIView.animate(
                    withDuration: animationDuration,
                    animations: {
                        self.setNeedsStatusBarAppearanceUpdate()
                })
                
            } else {
                // View controller based so animate away
                statusBarShouldBeHidden = hidden
                UIApplication.shared.setStatusBarHidden(hidden, with: animated ? UIStatusBarAnimation.slide : UIStatusBarAnimation.none)
            }
        }
        
        // Toolbar, nav bar and captions
        // Pre-appear animation positions for sliding
        if areControlsHidden && !hidden && animated {
            // Toolbar
            toolbar.frame = frameForToolbar.offsetBy(dx: 0, dy: animatonOffset)
            
            // Captions
            for page in visiblePages {
                if let v = page.captionView {
                    // Pass any index, all we're interested in is the Y
                    var captionFrame = frameForCaptionView(captionView: v, index: 0)
                    captionFrame.origin.x = v.frame.origin.x // Reset X
                    v.frame = captionFrame.offsetBy(dx: 0, dy: animatonOffset)
                }
            }
        }
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.navigationController?.setNavigationBarHidden(hidden, animated: true)
            
            // Toolbar
            self.toolbar.frame = self.frameForToolbar
            
            if hidden {
                self.toolbar.frame = self.toolbar.frame.offsetBy(dx: 0, dy: animatonOffset)
            }
            self.toolbar.alpha = hidden ? 0.0 : self.toolbarAlpha

            // Captions
            for page in self.visiblePages {
                if let v = page.captionView {
                    // Pass any index, all we're interested in is the Y
                    var captionFrame = self.frameForCaptionView(captionView: v, index: 0)
                    captionFrame.origin.x = v.frame.origin.x // Reset X
                    
                    if hidden {
                        captionFrame = captionFrame.offsetBy(dx: 0, dy: animatonOffset)
                    }
                    
                    v.frame = captionFrame
                    v.alpha = hidden ? 0.0 : self.captionAlpha
                }
            }
            
            // Selected buttons
            for page in self.visiblePages {
                if let button = page.selectedButton {
                    let v = button
                    var newFrame = self.frameForSelectedButton(selectedButton: v, atIndex: 0)
                    newFrame.origin.x = v.frame.origin.x
                    v.frame = newFrame
                }
            }
        })
        
        // Controls
        if !permanent {
            hideControlsAfterDelay()
        }
    }

    /// prefersStatusBarHidden
    public override var prefersStatusBarHidden: Bool {
        if !leaveStatusBarAlone {
            return statusBarShouldBeHidden
        }
        
        return presentingViewControllerPrefersStatusBarHidden
    }
    
    /// preferredStatusBarUpdateAnimation
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    func cancelControlHiding() {
        // If a timer exists then cancel and release
        if controlVisibilityTimer != nil {
            controlVisibilityTimer!.invalidate()
            controlVisibilityTimer = nil
        }
    }

    // Enable/disable control visiblity timer
    func hideControlsAfterDelay() {
        if !areControlsHidden {
            cancelControlHiding()
            
            controlVisibilityTimer = Timer.scheduledTimer(
                timeInterval: delayToHideElements,
                target: self,
                selector: #selector(MediaBrowser.hideControls),
                userInfo: nil,
                repeats: false)
        }
    }

    var areControlsHidden: Bool {
        return 0.0 == toolbar.alpha
    }
    
    func hideControls() {
        setControlsHidden(hidden: true, animated: true, permanent: false)
    }
    
    func showControls() {
        setControlsHidden(hidden: false, animated: true, permanent: false)
    }
    
    func toggleControls() {
        setControlsHidden(hidden: !areControlsHidden, animated: true, permanent: false)
    }

    //MARK: - Properties

    var currentPhotoIndex: Int {
        set(i) {
            var index = i
        
            // Validate
            let photoCount = numberOfMedias
        
            if 0 == photoCount {
                index = 0
            }
            else
            if index >= photoCount {
                index = photoCount - 1
            }
            
            currentPageIndex = index
        
            if isViewLoaded {
                jumpToPageAtIndex(index: index, animated: false)
                if !viewIsActive {
                    tilePages() // Force tiling if view is falset visible
                }
            }
        }
        
        get {
            return currentPageIndex
        }
    }

    //MARK: - Misc

    func doneButtonPressed(sender: AnyObject) {
        // Only if we're modal and there's a done button
        if doneButton != nil {
            // See if we actually just want to show/hide grid
            if enableGrid {
                if startOnGrid && nil == gridController {
                    showGrid(animated: true)
                    return
                }
                else
                if !startOnGrid && gridController != nil {
                    hideGrid()
                    return
                }
            }
        
            // Dismiss view controller
            // Call delegate method and let them dismiss us
            if let d = delegate {
                d.mediaBrowserDidFinishModalPresentation(mediaBrowser: self)
            }
            // dismissViewControllerAnimated:true completion:nil]
        }
    }

    //MARK: - Actions

    func actionButtonPressed(_ sender: Any) {
        // Only react when image has loaded
        if let photo = mediaAtIndex(index: currentPageIndex) {
            if numberOfMedias > 0 && photo.underlyingImage != nil {
                // If they have defined a delegate method then just message them
                // Let delegate handle things
                if let d = delegate {
                    d.actionButtonPressed(at: currentPageIndex, in: self)
                }

                // Show activity view controller
                var items: [Any] = [Any]()
                if let image = photo.underlyingImage {
                    items.append(image)
                }
                if photo.caption != "" {
                    items.append(photo.caption)
                }
                activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                
                // Show
                if let vc = self.activityViewController {
                    vc.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, activityError) in
                        guard let wself = self else { return }

                        wself.activityViewController = nil
                        wself.hideControlsAfterDelay()
                    }
                    vc.popoverPresentationController?.barButtonItem = actionButton

                    self.present(vc, animated: true, completion: nil)
                }
                
                // Keep controls hidden
                setControlsHidden(hidden: false, animated: true, permanent: true)
            }
        }
    }
}
