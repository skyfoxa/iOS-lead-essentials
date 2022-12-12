import UIKit

// Level 1

// API module

class APIClient_L1 {
    static let shared = APIClient_L1()
    
    func login(completion: () -> Void) {}
    func loadFeed(completion: () -> Void) {}
}

// Login module

class LoginVC_L1: UIViewController {
    var api = APIClient_L1.shared
    
    func login() {
        api.login {
            // Show main view
        }
    }
}

// Feed module

class FeedVC_L1: UIViewController {
    var api = APIClient_L1.shared
    
    func loadFeed() {
        api.loadFeed {
            // Update UI
        }
    }
}

// Level 2

// API module

class APIClient_L2 {
    static let shared = APIClient_L2()
    
    func request(_ urlSession: URLSession, completion: (Data) -> Void) {}
}

// Login module

extension APIClient_L2 {
    func login(completion: () -> Void) {
        self.request(.shared) { _ in
            completion()
        }
    }
}

class LoginVC_L2: UIViewController {
    var api = APIClient_L2.shared
    
    func login() {
        api.login {
            // Show main view
        }
    }
}

// Feed module

extension APIClient_L2 {
    func loadFeed(completion: () -> Void) {
        self.request(.shared) { _ in
            completion()
        }
    }
}

class FeedVC_L2: UIViewController {
    var api = APIClient_L2.shared
    
    func loadFeed() {
        api.loadFeed {
            // Update UI
        }
    }
}

// Level 3

// Main module

extension APIClient_L3: LoginClient {
    func login(completion: () -> Void) {
        self.request(.shared) { _ in
            completion()
        }
    }
}

extension APIClient_L3: FeedClient {
    func loadFeed(completion: () -> Void) {
        self.request(.shared) { _ in
            completion()
        }
    }
}

let vc = LoginVC_L3()
vc.api = APIClient_L3.shared


// API module

class APIClient_L3 {
    static let shared = APIClient_L3()
    
    func request(_ urlSession: URLSession, completion: (Data) -> Void) {}
}

// Login module

public protocol LoginClient {
    func login(completion: () -> Void)
}

class LoginVC_L3: UIViewController {
    var api: LoginClient!
    
    func login() {
        api.login {
            // Show main view
        }
    }
}

// Feed module

public protocol FeedClient {
    func loadFeed(completion: () -> Void)
}

class FeedVC_L3: UIViewController {
    var api: FeedClient!
    
    func loadFeed() {
        api.loadFeed {
            // Update UI
        }
    }
}

// Level 4

// Main module

struct ApiLoginFeature: LoginClient_L4 {
    let api: APIClient_L4
    func login(completion: () -> Void) {
        api.request(.shared) { _ in
            completion()
        }
    }
}

struct APIFeedFeature: FeedClient_L4 {
    let api: APIClient_L4
    func loadFeed(completion: () -> Void) {
        api.request(.shared) { _ in
            completion()
        }
    }
}

let vc2 = LoginVC_L4()
vc2.api = ApiLoginFeature(api: APIClient_L4.shared)


// API module

class APIClient_L4 {
    static let shared = APIClient_L4()
    
    func request(_ urlSession: URLSession, completion: (Data) -> Void) {}
}

// Login module

public protocol LoginClient_L4 {
    func login(completion: () -> Void)
}

class LoginVC_L4: UIViewController {
    var api: LoginClient_L4!
    
    func login() {
        api.login {
            // Show main view
        }
    }
}

// Feed module

public protocol FeedClient_L4 {
    func loadFeed(completion: () -> Void)
}

class FeedVC_L4: UIViewController {
    var api: FeedClient_L4!
    
    func loadFeed() {
        api.loadFeed {
            // Update UI
        }
    }
}
