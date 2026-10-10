# Database and deployment

The Supabase schema is created separately in the Supabase SQL Editor. The
application does not migrate data from a local database and Hibernate schema
generation remains disabled (`spring.jpa.hibernate.ddl-auto=none`).

Incremental SQL changes are kept in `migrations/`. The backend initializer
creates the chat read-state table and required catalogs when absent. Do not
run the test seed against a public database while account passwords are stored
in the current legacy format.

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
