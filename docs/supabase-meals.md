# Connect private meal storage

1. Run `supabase/migrations/202609140001_create_meals.sql` in the Supabase SQL Editor once.
2. In the existing Azure App Service `foodtracker-api`, add these environment variables and apply the changes:
   - `SUPABASE_URL`: `https://occtpttbvixhsvtfhkmq.supabase.co`
   - `SUPABASE_PUBLISHABLE_KEY`: the same public key used in `AuthModel.swift`.
3. Deploy the updated backend with `bash scripts/deploy_azure.sh` after signing into Azure CLI.
4. Rebuild the iOS app and log in. Save a meal, refresh History, and verify its row in Supabase. Restart the backend and confirm the meal remains.
5. Log out and sign in with a second account. The first account's meals must not appear. Save another meal, then return to the first account and verify isolation in both directions.

Flask validates the bearer token with Supabase Auth and forwards it to the Data API using the publishable key. RLS remains active; no service-role key is required. Every production API route requires authentication. Missing Supabase configuration fails closed instead of storing shared meals in memory. Existing app installations without authentication must be updated.

Only the test configuration uses in-memory storage. Saving uses a per-user request ID to keep retries from creating duplicate meals. Dates currently represent the time saved, displayed in the phone's local timezone. No images or image URLs are inserted into the table.

The basic login session expires without automatic refresh. If the API reports an expired session, log out and log back in.
