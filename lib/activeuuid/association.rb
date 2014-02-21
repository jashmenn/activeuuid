require 'active_record'
require 'active_record/associations/preloader/association'

module ActiveRecord::Associations
  class Preloader
    class Association
      def owners_by_key
        @owners_by_key ||= owners.group_by do |owner|
          key = owner[owner_key_name]
          # NOTE: key.to_s screws up the literal in the `WHERE ... IN (...)` clause
          # in AR::Base.includes... so we patch and comment it out.
          key # && key.to_s
        end
      end

      def associated_records_by_owner
        owners_map = owners_by_key
        owner_keys = owners_map.keys.compact

        if klass.nil? || owner_keys.empty?
          records = []
        else
          # Some databases impose a limit on the number of ids in a list (in Oracle it's 1000)
          # Make several smaller queries if necessary or make one query if the adapter supports it
          sliced  = owner_keys.each_slice(model.connection.in_clause_length || owner_keys.size)
          records = sliced.map { |slice| records_for(slice) }.flatten
        end

        # Each record may have multiple owners, and vice-versa
        records_by_owner = Hash[owners.map { |owner| [owner, []] }]
        records.each do |record|
          owner_key = record[association_key_name].to_s
          # NOTE: #to_s screws up the literal in the `WHERE ... IN (...)` clause
          # in AR::Base.includes... so we patch and comment it out.
          owner_key = record[association_key_name] # .to_s

          owners_map[owner_key].each do |owner|
            records_by_owner[owner] << record
          end
        end
        records_by_owner
      end
    end
  end
end