# LoL Champion Rotation

Backend service featuring League of Legends free champions rotations.

## Environment variables

The application uses a `.env` file to provide necessary configuration at runtime. The following variables must be defined:

| Variable                      | Description |
|-------------------------------|-------------|
| APP_MANAGEMENT_KEY            | Secret key used to authorize management endpoints (see [ManagementRoutes.swift](Sources/App/Routes/ManagementRoutes.swift) for the list of endpoints)
| APP_ALLOWED_ORIGINS           | Comma-separated list of allowed origins for CORS
| B2_APP_KEY_ID                 | Backblaze B2 application key ID
| B2_APP_KEY_SECRET             | Backblaze B2 application key secret
| DATABASE_URL                  | Connection string for the database used in production
| TEST_DATABASE_URL             | Connection string for the database used during tests
| RIOT_API_KEY                  | API key for accessing the Riot Games API
| FCM_SERVICE_ACCOUNT_KEY_PATH  | Relative path to Firebase Cloud Messaging service account JSON file
| ID_HASHER_SEED                | Seed used for generating hashed identifiers
| FIREBASE_PROJECT_ID           | Firebase project identifier

## Required Database Data

The application requires the database to contain a single-entry initial configuration in the tables listed below.

### `champion-rotation-configs`

Defines configuration related to the champion rotation updates.

| Field | Type | Description |
|-------|------|-------------|
| `rotation_change_weekday` | `Int` | Day of the week when the champion rotation updates (1 = Monday, 7 = Sunday) |

## Related Projects

- [LoL Champion Rotation Mobile](https://github.com/tomwyr/lol-champion-rotation-mobile) - Mobile version of the application.
- [LoL Champion Rotation Web](https://github.com/tomwyr/lol-champion-rotation-web) - Web version of the application.
