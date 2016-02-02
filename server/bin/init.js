var fs = require('fs');
var pg = require('pg').native;
var config = require('../lib/config');
var oldConfig;
var realConfig = JSON.parse(fs.readFileSync(__dirname + '/../config/config.' + process.env.NODE_ENV + '.json', 'utf8'));
var dbConfig = realConfig.database;

function connect(callback) {
  'use strict';

  pg.connect(config.database, function(err, client, done) {
    if (err) {
      console.log(err);
      process.exit(1);
    }

    callback(client, done);
  });
}

function createUser(callback) {
  'use strict';

  console.log('Creating user...');

  connect(function(client, done) {
    var query = {
      text: 'create user ' + dbConfig.user + ' with encrypted password \'' + dbConfig.password + '\'',
    };

    client.query(query, function(err, result) {
      done();

      if (err) {
        console.log(err);
        return callback();
      }

      console.log('User created');
      callback();
    });
  });
}

function createDatabase(callback) {
  'use strict';

  console.log('Creating database...');

  connect(function(client, done) {
    var query = {
      text: 'create database ' + dbConfig.database + ' with owner = ' + dbConfig.user,
    };

    client.query(query, function(err, result) {
      done();

      if (err) {
        console.log(err);
        return callback();
      }

      console.log('Database created');
      callback();
    });
  });
}

function createSchema(callback) {
  'use strict';

  console.log('Creating schema...');

  connect(function(client, done) {
    var file = fs.readFileSync(__dirname + '/../lib/stores/postgres/sql/setup.sql').toString();
    var query = {
      text: file,
    };

    client.query(query, function(err, result) {
      done();

      if (err) {
        console.log(err);
        return callback();
      }

      console.log('Schema created');
      callback();
    });
  });
}

module.exports = function() {
  'use strict';

  oldConfig = JSON.parse(JSON.stringify(config));
  config.database.user = 'postgres';
  config.database.database = 'postgres';

  createUser(function() {
    createDatabase(function() {
      config = oldConfig;
      createSchema(function() {
        console.log('Done');
        process.exit();
      });
    });
  });
};
