import Cocoa

// Add workspace management imports
import CoreGraphics
import ApplicationServices

// CGSInternal declarations
private let kCGSAllSpacesMask: Int32 = 0xFF

private struct CGSSpace {
    static let kCGSSpaceAll: Int32 = 0
    static let kCGSSpaceUser: Int32 = 1
    static let kCGSSpaceFullscreen: Int32 = 2
}

// Private API declarations with proper types
private let _CGSDefaultConnection: () -> Int32 = {
    unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "_CGSDefaultConnection"),
                  to: (@convention(c) () -> Int32).self)
}()

private let CGSGetActiveSpace: (Int32) -> Int32 = {
    unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGSGetActiveSpace"),
                  to: (@convention(c) (Int32) -> Int32).self)
}()

private let CGSCopySpaces: (Int32, Int32) -> CFArray? = {
    unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGSCopySpaces"),
                  to: (@convention(c) (Int32, Int32) -> CFArray?).self)
}()

private let CGSSpaceCopyName: (Int32, Int32) -> CFString? = {
    unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGSSpaceCopyName"),
                  to: (@convention(c) (Int32, Int32) -> CFString?).self)
}()

@_silgen_name("CGSCopyManagedDisplaySpaces") 
public func CGSCopyManagedDisplaySpaces(_ connection: Int32) -> CFArray

@_silgen_name("CGSCopyActiveMenuBarDisplayIdentifier")
public func CGSCopyActiveMenuBarDisplayIdentifier(_ connection: Int32) -> CFString

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var updateTimer: Timer?
    private var activeWorkspace: ActiveWorkspace!
    private var lastActiveSpace: Int32 = 0  // Add this to track the last space
    private var backgroundColor: NSColor {
        if #available(macOS 10.14, *) {
            return NSColor.controlAccentColor.withAlphaComponent(0.8)
        } else {
            return NSColor.systemBlue.withAlphaComponent(0.8)
        }
    }
    private let textColor = NSColor.white
    private let squareSize: CGFloat = 24  // Increased from 18 to allow for padding
    private let horizontalPadding: CGFloat = 6  // 3 points on each side
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: squareSize)
        
        // Initialize ActiveWorkspace with self as delegate
        activeWorkspace = ActiveWorkspace(delegate: self)
        
        // Configure the status item
        statusItem.isVisible = true
        if let button = statusItem.button {
            button.wantsLayer = true
            button.layer?.cornerRadius = 3
            button.layer?.masksToBounds = true
            
            // Center the text and add some padding using frame insets
            button.alignment = .center
            button.imagePosition = .noImage  // Ensure only text is shown
            
            // Set initial appearance
            updateButtonAppearance(number: 1)
        }
        
        setupMenu()
        updateWorkspaceInfo()
        setupNotifications()
        
        // More frequent updates for testing
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateWorkspaceInfo()
        }
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    private func setupNotifications() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()
        
        // Workspace notifications
        let workspaceNotifications: [(NotificationCenter, NSNotification.Name)] = [
            (notificationCenter, NSWorkspace.activeSpaceDidChangeNotification),
            (notificationCenter, NSWorkspace.didActivateApplicationNotification),
            (notificationCenter, NSWorkspace.didLaunchApplicationNotification),
            (notificationCenter, NSWorkspace.didTerminateApplicationNotification),
            (distributedCenter, NSNotification.Name("com.apple.spaces.switchedSpaces")),
            (distributedCenter, NSNotification.Name("com.apple.screenIsChanged"))
        ]
        
        // Add observers for workspace changes
        for (center, notification) in workspaceNotifications {
            center.addObserver(
                self,
                selector: #selector(updateWorkspaceInfo),
                name: notification,
                object: nil
            )
        }
        
        // Separate observer for accent color changes
        distributedCenter.addObserver(
            self,
            selector: #selector(updateAccentColor),
            name: NSNotification.Name("AppleColorPreferencesChangedNotification"),
            object: nil
        )
    }
    
    private func updateButtonAppearance(number: Int) {
        guard let button = statusItem.button else { return }
        
        // Create attributed string for the number
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let attributedString = NSAttributedString(string: "\(number)", attributes: attrs)
        
        button.attributedTitle = attributedString
        button.layer?.backgroundColor = backgroundColor.cgColor
    }
    
    @objc internal func updateWorkspaceInfo() {
        let conn = _CGSDefaultConnection()
        let activeSpace = CGSGetActiveSpace(conn)
        
        // Only print if the space has changed
        if activeSpace != lastActiveSpace {
            let displays = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
            let activeDisplay = CGSCopyActiveMenuBarDisplayIdentifier(conn) as String
            let allSpaces: NSMutableArray = []
            var activeSpaceID = -1
            
            // Find active space ID and collect non-fullscreen spaces
            for display in displays {
                guard
                    let current = display["Current Space"] as? [String: Any],
                    let spaces = display["Spaces"] as? [[String: Any]],
                    let dispID = display["Display Identifier"] as? String
                else {
                    continue
                }
                
                // Get active space ID from main/active display
                if dispID == "Main" || dispID == activeDisplay {
                    activeSpaceID = current["ManagedSpaceID"] as! Int
                }
                
                // Collect only non-fullscreen spaces
                for space in spaces {
                    let isFullscreen = space["TileLayoutManager"] as? [String: Any] != nil
                    if !isFullscreen {
                        allSpaces.add(space)
                    }
                }
            }
            
            // Find and update space number
            for (index, space) in allSpaces.enumerated() {
                let spaceID = (space as! NSDictionary)["ManagedSpaceID"] as! Int
                if spaceID == activeSpaceID {
                    let spaceNumber = index + 1
                    print("Switched to Space Number: \(spaceNumber)")
                    DispatchQueue.main.async { [weak self] in
                        self?.updateButtonAppearance(number: spaceNumber)
                    }
                    break
                }
            }
            
            lastActiveSpace = activeSpace
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func updateAccentColor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let button = self.statusItem.button else { return }
            button.layer?.backgroundColor = self.backgroundColor.cgColor
        }
    }
}

class ActiveWorkspace {
    private let workspace = NSWorkspace.shared
    private weak var delegate: AppDelegate?
    
    init(delegate: AppDelegate) {
        self.delegate = delegate
    }
    
    func activateApp(_ bundleId: String) {
        // Get all running applications
        let runningApps = workspace.runningApplications
        
        // Find the app with matching bundle ID
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            // Use the new cooperative activation API
            app.activate()
            // Update the workspace info after activation
            delegate?.updateWorkspaceInfo()
        }
    }
    
    func launchApp(_ bundleId: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            print("Could not find application with bundle ID: \(bundleId)")
            return
        }
        
        let config = NSWorkspace.OpenConfiguration()
        
        // Launch the app asynchronously using the app URL
        workspace.openApplication(at: appURL,
                               configuration: config,
                               completionHandler: { [weak self] running, error in
            if let error = error {
                print("Failed to launch app: \(error.localizedDescription)")
            } else {
                // Update the workspace info after successful launch
                DispatchQueue.main.async {
                    self?.delegate?.updateWorkspaceInfo()
                }
            }
        })
    }
}

func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

main()