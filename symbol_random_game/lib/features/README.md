# Features

Each folder owns the screens, models, and API services for one game feature:

- `auth`: sign-in, registration, and user data.
- `home`: main menu and navigation.
- `game`: solo/duel gameplay and operation challenges.
- `settings`: preferences and configuration.
- `leaderboard`: scores and ranking display.
- `profile`: profile, achievements, reviews, and account deletion.
- `friends`: friendship requests and friend list.
- `chat`: messages between friends.

Shared UI, app-wide configuration, networking, and audio stay in `shared/`,
`core/`, and `audio/` respectively.
