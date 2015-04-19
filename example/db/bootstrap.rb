require 'sqlite3'
require 'humanize'

db = SQLite3::Database.new 'database.sqlite'
db.execute 'CREATE TABLE IF NOT EXISTS rows (str VARCHAR(255), num int);'
db.execute 'DELETE FROM rows;'

0.upto(1000).each do |i|
  db.execute "INSERT INTO rows (str, num) VALUES (?, ?)", [i.humanize, i]
end

db.execute 'CREATE TABLE IF NOT EXISTS skip (id int);'
db.execute 'DELETE FROM skip;'
db.execute 'INSERT INTO skip (id) VALUES (1);'

