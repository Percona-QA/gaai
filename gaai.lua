-- Original small lua pquery example script: Created by Alexey Kopytov, Percona LLC
--   Ref https://github.com/Percona-QA/percona-qa/tree/master/sql-sb (GPLv2 Licensed)
-- Copyright (c) 2018 Roel Van de Paar, Percona LLC 

queries = {}

function thread_init(thread_id)
   local file = assert(io.open(sql_file, "r"))
   local i = 1
   for line in file:lines() do
      queries[i] = line
      i = i + 1
   end
end

function event(thread_id)
   db_query(queries[sb_rand_uniform(1, #queries)])
end
