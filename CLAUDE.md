# Project Guidelines for Claude

## Research and Documentation

When working with platform APIs (iOS, Android, or any vendor SDK):

1. **Always check official documentation first.**
   - iOS / macOS / visionOS: https://developer.apple.com/documentation
   - Android: https://developer.android.com/reference
   - React Native: https://reactnative.dev/docs/getting-started

2. **For Apple APIs, prefer the SDK swiftinterface files** when the documentation site requires JavaScript or is otherwise unreachable. These files contain the ground-truth type signatures and are available locally at:

   ```
   /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/<Framework>.framework/Modules/<Framework>.swiftmodule/arm64e-apple-ios.swiftinterface
   ```

3. **Only use third-party articles, blog posts, or community examples as supplementary sources** — after the official docs have been checked. Never treat them as the primary reference for API property names, method signatures, or type structures.

4. **Never guess API property names.** If official docs are unavailable and the swiftinterface/header cannot be found, say so explicitly and ask the user to verify before writing the code.
