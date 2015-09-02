require 'active_record/schema_dumper'

class ActiveRecord::SchemaDumper
  private
  def spec_for_column(column)
    spec = {}
    spec[:name]      = column.name.inspect

    # AR has an optimization which handles zero-scale decimals as integers. This
    # code ensures that the dumper still dumps the column as a decimal.
    spec[:type]      = case column.type
                       when :integer
                         column.sql_type =~ /^(numeric|decimal)/ ? 'decimal' : 'integer'
                       when :string
                         column.sql_type == 'uuid' ? 'uuid' : 'string'
                       else
                         column.type.to_s
                       end
    spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && spec[:type] != 'decimal'
    spec[:precision] = column.precision.inspect if column.precision
    spec[:scale]     = column.scale.inspect if column.scale
    spec[:null]      = 'false' unless column.null
    spec[:default]   = default_string(column.default) if column.has_default?
    (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
    spec
  end

  # Adapted from rails 3.2 code
  def table(table, stream)
    columns = @connection.columns(table)
    begin
      tbl = StringIO.new

      # first dump primary key column
      if @connection.respond_to?(:primary_key)
        pk = @connection.primary_key(table)
      elsif @connection.respond_to?(:pk_and_sequence_for)
        pk, _ = @connection.pk_and_sequence_for(table)
      end

      tbl.print "  create_table #{remove_prefix_and_suffix(table).inspect}"
      if columns.detect { |c| c.name == pk && c.type == :integer}
        if pk != 'id'
          tbl.print %Q(, :primary_key => "#{pk}")
        end
      else
        tbl.print ", :id => false"
      end
      tbl.print ", :force => true"
      tbl.puts " do |t|"

      # then dump all non-primary key columns
      column_specs = columns.map do |column|
        raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
        next if column.name == pk
        spec_for_column column
      end.compact

      # explicitly prepend non-integer primary key
      if col = columns.detect { |c| c.name == pk && c.type != :integer}
        pk_spec = spec_for_column col
        pk_spec.delete(:null)
        pk_spec[:primary_key] = ":primary_key => true"
        column_specs.unshift pk_spec
      end

      # find all migration keys used in this table
      keys = [:name, :limit, :precision, :scale, :default, :null, :primary_key] & column_specs.map{ |k| k.keys }.flatten

      # figure out the lengths for each column based on above keys
      lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

      # the string we're going to sprintf our values against, with standardized column widths
      format_string = lengths.map{ |len| "%-#{len}s" }

      # find the max length for the 'type' column, which is special
      type_length = column_specs.map{ |column| column[:type].length }.max

      # add column type definition to our format string
      format_string.unshift "    t.%-#{type_length}s "

      format_string *= ''

      column_specs.each do |colspec|
        values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
        values.unshift colspec[:type]
        tbl.print((format_string % values).gsub(/,\s*$/, ''))
        tbl.puts
      end

      tbl.puts "  end"
      tbl.puts

      indexes(table, tbl)

      tbl.rewind
      stream.print tbl.read
    rescue => e
      stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
      stream.puts "#   #{e.message}"
      stream.puts
      puts e
      puts e.backtrace
    end

    stream
  end
end
