# Run the initial iOS sample

## Source and scope

This is Apple's completed **Passing Data with Bindings** tutorial project, part of Scrumdinger. Its meeting editor accepts a title, duration, theme, and attendee names. It is the existing sample for the assignment, not an original student implementation. Source files and Apple license notices are preserved.

Tutorial: https://developer.apple.com/tutorials/app-dev-training/passing-data-with-bindings

Download: https://developer.apple.com/tutorials/downloads/com.apple.app-dev-training/PassingDataWithBindings.zip

Imported folder: `Complete` → `ios/Scrumdinger`.

This stage stores edits in memory; persistence and a deployed REST backend have not been added. Do not assume changes survive an app restart.

## Open and run

1. Open `ios/Scrumdinger/Scrumdinger.xcodeproj` in Xcode. Allow its two local packages, ThemeKit and TimerKit, to resolve.
2. Connect and unlock your iPhone. Respond to any Trust prompts on your devices.
3. In Xcode Settings → Accounts, add your Apple Account if needed.
4. Select the project in the navigator, then the Scrumdinger app target → Signing & Capabilities. Enable automatic signing and select your own Personal Team.
5. Set a unique bundle identifier if required, for example `edu.gatech.yourusername.Scrumdinger`. Each partner uses their own signing team; avoid committing personal signing changes with unrelated work.
6. Select your physical iPhone as the run destination. The project targets iOS 18.2 or later; Xcode must also support your phone's installed iOS version.
7. If Xcode asks for Developer Mode, follow its instructions on your phone and restart the phone if prompted.
8. Press Run (Command-R). Any required iOS platform components may need downloading first.

## Demonstrate input

Open a meeting → Edit → change its title, move the duration slider, and add an attendee → Done. Confirm that the updated title, duration, and attendee appear. These steps have not yet been tested on a device in this project.

## Record for submission

- Xcode project open and the selected physical-device destination.
- App on the iPhone before and after editing, with captions describing the input and result.
- Any setup/build errors, attempted fixes, and what you learned.
- The sample import commit and the annotated Apple reference.

Do not expose account identifiers, device identifiers, or signing credentials in screenshots.

## Verification so far — September 7, 2026

Xcode 26.6 first-launch check passes; iOS 26.5 SDK is installed. Automated unsigned build was attempted but did not complete. Initial Swift package cache permission failures were addressed through granted cache access and a workspace module-cache path. The remaining failure is `sandbox-exec: sandbox_apply: Operation not permitted` during package resolution. Simulator/device discovery also failed to connect to macOS services from the sandbox. This does not establish a fault in the sample or that the phone is disconnected. Xcode UI control timed out, so a GUI build was not verified either.

Next verification: build and run through Xcode on the physical iPhone. No successful build or device deployment is claimed yet.
