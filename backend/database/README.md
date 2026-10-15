# Database and deployment

The complete database structure is in `symbol_random_game.sql`. Run that file
in the Supabase SQL Editor when creating a new database. It contains the tables,
constraints, and indexes used by the API. Hibernate schema generation remains
disabled (`spring.jpa.hibernate.ddl-auto=none`).

The backend initializer keeps existing deployments compatible and inserts
required catalogs when absent. No test accounts are created by the schema.

## Render backend

Render builds the Spring Boot API from `Dockerfile`; `docker-compose.yml` is
not part of deployment. Configure the Render Web Service with this repository
and `backend` as its root directory. Add the following environment variables
in Render, using the Session Pooler values shown by Supabase:

```text
DB_URL=jdbc:postgresql://<session-pooler-host>:<port>/postgres?sslmode=require
DB_USERNAME=<session-pooler-user>
DB_PASSWORD=<Supabase database password>
```

Keep the password in Render's environment settings; never commit it or put it
in Flutter. Render supplies `PORT`, which Spring Boot uses automatically.
Flutter should connect to the deployed API URL, not to PostgreSQL directly.
