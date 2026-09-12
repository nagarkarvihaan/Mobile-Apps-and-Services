# FoodTracker acceptance checks

Record actual outcomes and screenshots after running these on a physical iPhone. Automated tests do not establish device execution, live AI accuracy, hosting deployment, or partner collaboration.

1. Launch the updated FoodTracker and confirm Today and History load automatically from Azure, including after previously saving a localhost URL.
2. Tap Take Photo. Allow camera access, photograph food, and check the preview. Cancel the camera once and ensure the app remains usable.
3. Choose a library image, including a large/rotated HEIC photo. Check orientation and preview. PhotosPicker does not require full-library permission.
4. Estimate nutrition. Confirm loading feedback and an editable result. Edit the meal name and all four numbers. Save and verify the edited values in Today and History.
5. Add another meal. Verify calorie/protein/carbs/fat totals. Today should include only meals on the phone's current local date.
6. Clear a number, enter an invalid name, and enter a value outside the allowed range. Save should stay disabled; zero remains valid. Try a locale using comma decimals.
7. Disable network access during analysis and during save. Verify readable errors, retry behavior, and a single saved meal after retry. If the save remains uncertain, use Close and Check History before adding it again.
8. Deny camera permission and try again. Verify guidance and the photo-library alternative. Test an image containing no food and an unavailable Gemini service.
9. Pull to refresh History. Restart the backend and refresh again; temporary meals should disappear. Restart the app while the same backend stays running; history should reload from the server.
10. Check light/dark mode, large text, and VoiceOver labels. Capture the app on the physical phone, the backend HTTPS result, the successful Actions run, and each partner's genuine Git contribution.

## Automated verification recorded September 10, 2026

The implementation session verified 35 backend API/provider tests, 10 Swift shared-logic tests, and seven mocked deployment/signing automation tests. All passed. Python lint, workflow YAML parsing, Xcode project/plist validation, and complete iOS Swift source type-checking also passed. A real local Gunicorn HTTP smoke test verified health, meal creation, and history. Container validation is configured in CI; a local container build has not been verified.

The local Xcode 26.6 installation has iOS SDK 26.5 but no simulator runtimes. Full Xcode builds currently stop during asset compilation/destination selection because the platform runtime is missing. Install it from Xcode → Settings → Components, then build and run the app. Separate Swift compiler checks can validate the sources but do not replace a complete simulator/device build.

Update: Azure deployment and a live Gemini blank-image request were verified September 12; see azure-deployment.md. Real-food and physical-device acceptance still need to be demonstrated.
