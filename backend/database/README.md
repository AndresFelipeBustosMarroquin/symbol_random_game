# Database

`symbol_random_game.sql` is the complete PostgreSQL schema and seed-data export.
Incremental, non-destructive schema improvements belong in `migrations/` and
must be applied to existing databases before deploying code that depends on
them.

Apply a migration with:

```powershell
Get-Content .\database\migrations\001_query_indexes.sql -Raw |
  docker exec -i symbol_random_game_postgres psql -U postgres -d symbol_random_game_bd -v ON_ERROR_STOP=1
```

The index migration is safe to run more than once. It enforces one level per
mode/settings combination and adds indexes for the leaderboard and relationship
lists.
