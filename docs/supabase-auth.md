# Basic Supabase login

1. In your Supabase project, enable the Email provider under Authentication.
2. Copy the project URL and publishable key into `SupabaseConfig` in `ios/FoodTracker/FoodTracker/Auth/AuthModel.swift`. A legacy anon key also works. Never use a secret or service-role key in the app.
3. Run the app and choose **Create an account**. If email confirmation is enabled, open the confirmation email, confirm in the browser, then return to the app and log in. Configure your Supabase Site URL to a reachable confirmation landing page; this basic flow does not consume deep links.
4. Verify that login opens the Today tab and Settings shows your email. Log Out should return to login. Try an incorrect password and confirm an error appears.

This first step uses the Supabase Auth REST API with email and password. Passwords are not saved. Sessions are held in memory, so restarting the app requires login again. Expired sessions are cleared when the app returns to the foreground. Persistent sessions and password recovery are deferred.

Meal endpoints now verify bearer tokens in Flask and forward the user's token to Supabase for owner-scoped storage. Complete [meal storage setup](supabase-meals.md), including deployment, before testing private history against Azure.

Reference: https://supabase.com/docs/guides/auth/passwords
