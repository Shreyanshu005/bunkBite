//
//  CustomButton.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Constants.primaryColor)
                    .frame(height: 56)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .disabled(isLoading)
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.system(size: 16))
                .padding()
                .background(Constants.lightGray)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Constants.primaryColor : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
        }
    }
}

struct OTPTextField: View {
    @Binding var otp: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                OTPDigitView(digit: getDigit(at: index), isFocused: isFocused && index == otp.count)
            }
        }
        .background(
            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .onChange(of: otp) { oldValue, newValue in
                    if newValue.count > 6 {
                        otp = String(newValue.prefix(6))
                    }
                }
        )
        .onTapGesture {
            isFocused = true
        }
    }

    private func getDigit(at index: Int) -> String? {
        guard index < otp.count else { return nil }
        return String(otp[otp.index(otp.startIndex, offsetBy: index)])
    }
}

struct OTPDigitView: View {
    let digit: String?
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Constants.lightGray)
                .frame(width: 50, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Constants.primaryColor : Color.clear, lineWidth: 2)
                )

            if let digit = digit {
                Text(digit)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.textColor)
            } else if isFocused {
                Rectangle()
                    .fill(Constants.primaryColor)
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
            }
        }
    }
}
