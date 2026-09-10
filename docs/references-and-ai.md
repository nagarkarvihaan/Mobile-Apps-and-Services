# References and AI assistance

## FoodTracker implementation — September 10, 2026

At Aaron's request, Codex implemented the supplied Phase 1 plan: a separate SwiftUI FoodTracker project, Flask/Gemini REST flow, editable nutrition estimates, shared in-memory meals, automated tests, GitHub Actions CI, Render deployment automation, and optional TestFlight signing/upload automation. The Apple tutorial source remains unchanged.

References consulted for the implementation:

- [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output) and [Generate Content API](https://ai.google.dev/api/generate-content): JSON schema and image input; generated nutrition is also validated server-side.
- [Gemini model lifecycle](https://ai.google.dev/gemini-api/docs/deprecations): checked the configurable default model.
- [Render blueprint](https://render.com/docs/blueprint-spec), [runtime environment updates](https://api-docs.render.com/reference/update-env-var), and [deployment API](https://api-docs.render.com/reference/create-deploy): hosting configuration and deployment of the CI-tested SHA.
- [Apple build uploads](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds) and [Xcode distribution](https://developer.apple.com/videos/play/wwdc2021/10204/): signing and App Store Connect upload setup.

The new implementation and documentation were substantively generated with AI assistance. Students should review the code and record their own understanding, modifications, real-device demonstration, and partner contributions. Mocked tests do not establish a live Gemini, Render, or TestFlight integration.

Add references as they are used, with URLs, purpose, and what you learned. Each student should distinguish their own use from a teammate's.

## Assignment brief

The course assignment text supplied by Vihaan was used to create the checklist and submission outline. Add the Canvas assignment URL here when available.

## Apple developer account guidance

https://developer.apple.com/help/account/basics/about-your-developer-account

Consulted September 7, 2026, to explain personal device testing with an Apple Account. Device signing has not yet been tested in this project.

## Codex assistance — September 7, 2026

Tool: OpenAI Codex desktop app. Reference: https://developers.openai.com/codex/app/features

Requests included interpreting the assignment, explaining the iOS build workflow, identifying evidence to record, and setting up the shared repository.

Codex read the provided assignment, proposed milestones, checked Xcode and Git, cloned the repository, and prepared ignore rules and documentation/templates. The selected app, implementation, device testing, and backend are still pending. These documentation files were substantively drafted by AI and should be reviewed by each student.

Student reflection and verification: TODO — write what you personally checked, understood, changed, and learned. Do not present AI-generated reflections as your own experience.

## Reference entry template

- Title and URL:
- Date and participant:
- Used for:
- Code/content adapted:
- What I learned:

## AI entry template

- Date, participant, and tool:
- Prompt or concise accurate summary:
- Output used or changed:
- How I tested or verified it:
- What I learned:

## Apple — Passing Data with Bindings (September 7, 2026)

Tutorial: https://developer.apple.com/tutorials/app-dev-training/passing-data-with-bindings

Archive: https://developer.apple.com/tutorials/downloads/com.apple.app-dev-training/PassingDataWithBindings.zip

Used the completed Scrumdinger project as the original sample for the assignment. Preserved Apple licenses and Swift source. Learning topics to explore: SwiftUI forms, state, and bindings that update meeting details. Student learning and device execution remain to be recorded after actually working through the sample.

AI assistance: User requested remaining setup after completing Xcode first launch. Codex checked SDK/setup status, selected and imported the sample, inspected its editing flow, attempted builds, investigated sandbox errors, and drafted run/evidence instructions. No successful build, device run, or original app feature is claimed.
