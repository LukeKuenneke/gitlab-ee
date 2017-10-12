# Monkey patch to make it work with foreign data wrappers

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaStatements
        # Returns true if table exists.
        # If the schema is not specified as part of +name+ then it will only find tables within
        # the current schema search path (regardless of permissions to access tables in other schemas)
        def table_exists?(name)
          name = Utils.extract_schema_qualified_name(name.to_s)
          return false unless name.identifier

          exec_query(<<-SQL, 'SCHEMA').rows.first[0].to_i > 0
              SELECT COUNT(*)
              FROM pg_class c
              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE c.relkind IN ('r','v','m', 'f') -- (r)elation/table, (v)iew, (m)aterialized view, (f)oreign data wrapper
              AND c.relname = '#{name.identifier}'
              AND n.nspname = #{name.schema ? "'#{name.schema}'" : 'ANY (current_schemas(false))'}
          SQL
        end
      end
    end
  end
end
