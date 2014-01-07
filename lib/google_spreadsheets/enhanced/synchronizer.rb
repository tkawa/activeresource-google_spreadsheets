module GoogleSpreadsheets
  module Enhanced
    module Synchronizer

      # === Example
      # class User < ActiveRecord::Base
      #   extend GoogleSpreadsheets::Enhanced::Synchronizer
      #   sync_with :user_rows, spreadsheet_id: 'xxxx',
      #                         worksheet_title: 'users'
      #   after_commit :sync_user_row
      def sync_with(rows_name, options)
        options.assert_valid_keys(:spreadsheet_id, :worksheet_title, :class_name)
        options[:worksheet_title] ||= rows_name.to_s
        spreadsheet_class_name = LinkRelations.class_name_mappings['http://schemas.google.com/spreadsheets/2006#spreadsheet'].classify
        define_singleton_method(rows_name) do
          @worksheet ||= spreadsheet_class_name.constantize
                           .find(options[:spreadsheet_id])
                           .worksheets
                           .find_by!(title: options[:worksheet_title])
          @worksheet.rows
        end

        # inbound sync all (import)
        define_singleton_method("sync_with_#{rows_name}") do
          rows = send(rows_name) # FIXME: force reload
          records = rows.map do |row|
            record = self.find_or_initialize_by(id: row.id)
            row.aliased_attributes.each do |attr|
              record.send("#{attr}=", row.send(attr))
            end
            record
          end
          skipping_outbound_sync_of(records) do |records_with_skipped_outbound|
            transaction_if_possible do
              records_with_skipped_outbound.each(&:save)
            end
          end
        end

        # outbound sync one (export)
        define_method("sync_#{rows_name.to_s.singularize}") do
          return if @_skip_outbound_sync.tapp
          row = self.class.send(rows_name).find(self.id)
          if destroyed?
            row.destroy
          else
            # TODO: separate by AttributeAssignment
            row.aliased_attributes.each do |attr|
              value = self.attributes_before_type_cast[attr] || self.send(attr)
              row.send("#{attr}=", value)
            end
            row.save
          end
        end
      end

      private
      def transaction_if_possible(origin = self, &block)
        if origin.respond_to?(:transaction)
          origin.transaction(&block)
        elsif defined?(ActiveRecord)
          ActiveRecord::Base.transaction(&block)
        else
          yield # no transaction
        end
      end

      def skipping_outbound_sync_of(records)
        records = Array(records) unless records.is_a?(Enumerable)
        records.each do |record|
          record.instance_variable_set(:@_skip_outbound_sync, true)
        end
        yield records
      ensure
        records.each do |record|
          record.remove_instance_variable(:@_skip_outbound_sync) if record.instance_variable_defined?(:@_skip_outbound_sync)
        end
      end
    end
  end
end
