//
//  RazorpayCheckoutView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI
import WebKit

struct RazorpayCheckoutView: UIViewRepresentable {
    let paymentData: RazorpayPaymentInitiation
    let onSuccess: (RazorpayPaymentResponse) -> Void
    let onFailure: (String) -> Void
    let onDismiss: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onFailure: onFailure, onDismiss: onDismiss)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Add message handlers for payment callbacks
        userContentController.add(context.coordinator, name: "paymentSuccess")
        userContentController.add(context.coordinator, name: "paymentFailure")
        userContentController.add(context.coordinator, name: "paymentDismiss")
        
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Load HTML only once during creation
        let html = generateRazorpayHTML()
        webView.loadHTMLString(html, baseURL: nil)
        context.coordinator.hasLoaded = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Don't reload if already loaded - prevents reload on app resume
        if !context.coordinator.hasLoaded {
            let html = generateRazorpayHTML()
            webView.loadHTMLString(html, baseURL: nil)
            context.coordinator.hasLoaded = true
        }
    }
    
    private func generateRazorpayHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .loading {
                    text-align: center;
                    color: white;
                }
                .spinner {
                    border: 4px solid rgba(255, 255, 255, 0.3);
                    border-radius: 50%;
                    border-top: 4px solid white;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            </style>
        </head>
        <body>
            <div class="loading">
                <div class="spinner"></div>
                <p>Opening Razorpay Checkout...</p>
            </div>
            
            <script>
                var options = {
                    key: "\(paymentData.razorpayKeyId)",
                    amount: \(paymentData.amount),
                    currency: "\(paymentData.currency)",
                    order_id: "\(paymentData.razorpayOrderId)",
                    name: "BunkBite",
                    description: "Payment for Order \(paymentData.orderId)",
                    theme: {
                        color: "#667eea"
                    },
                    handler: function (response) {
                        // Payment successful
                        window.webkit.messageHandlers.paymentSuccess.postMessage({
                            razorpay_order_id: response.razorpay_order_id,
                            razorpay_payment_id: response.razorpay_payment_id,
                            razorpay_signature: response.razorpay_signature
                        });
                    },
                    modal: {
                        ondismiss: function() {
                            // User closed the payment modal
                            window.webkit.messageHandlers.paymentDismiss.postMessage({});
                        }
                    }
                };
                
                var rzp = new Razorpay(options);
                
                rzp.on('payment.failed', function (response){
                    // Payment failed
                    window.webkit.messageHandlers.paymentFailure.postMessage({
                        error: response.error.description,
                        code: response.error.code
                    });
                });
                
                // Auto-open checkout
                setTimeout(function() {
                    rzp.open();
                }, 500);
            </script>
        </body>
        </html>
        """
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onSuccess: (RazorpayPaymentResponse) -> Void
        let onFailure: (String) -> Void
        let onDismiss: () -> Void
        var hasLoaded = false
        
        init(onSuccess: @escaping (RazorpayPaymentResponse) -> Void,
             onFailure: @escaping (String) -> Void,
             onDismiss: @escaping () -> Void) {
            self.onSuccess = onSuccess
            self.onFailure = onFailure
            self.onDismiss = onDismiss
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("📱 Received message from JavaScript: \(message.name)")
            
            switch message.name {
            case "paymentSuccess":
                if let body = message.body as? [String: Any],
                   let response = RazorpayPaymentResponse(from: body) {
                    print("✅ Payment successful!")
                    print("Order ID: \(response.razorpayOrderId)")
                    print("Payment ID: \(response.razorpayPaymentId)")
                    onSuccess(response)
                }
                
            case "paymentFailure":
                if let body = message.body as? [String: Any],
                   let error = body["error"] as? String {
                    print("❌ Payment failed: \(error)")
                    onFailure(error)
                } else {
                    onFailure("Payment failed")
                }
                
            case "paymentDismiss":
                print("🚫 Payment dismissed by user")
                onDismiss()
                
            default:
                break
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString
                
                // Intercept UPI and other payment-related deep links
                if urlString.hasPrefix("upi://") || 
                   urlString.hasPrefix("phonepe://") || 
                   urlString.hasPrefix("paytmmp://") || 
                   urlString.hasPrefix("tez://") || 
                   urlString.hasPrefix("gpay://") || 
                   urlString.hasPrefix("whatsapp://") {
                    
                    UIApplication.shared.open(url, options: [:]) { success in
                        if !success {
                            print("❌ Failed to open deep link: \(urlString)")
                        }
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("🌐 WebView loaded successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to load: \(error.localizedDescription)")
            onFailure("Failed to load payment page")
        }
    }
}
