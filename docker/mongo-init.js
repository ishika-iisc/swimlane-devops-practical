/* global db */

const database = 'swimlane';
const appDb = db.getSiblingDB(database);

if (!appDb.getUser('swimlane')) {
  appDb.createUser({
    user: 'swimlane',
    pwd: 'swimlane-pass',
    roles: [{ role: 'readWrite', db: database }]
  });
}
