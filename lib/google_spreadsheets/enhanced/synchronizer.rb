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

        # import all
        define_singleton_method("sync_with_#{rows_name}") do
          rows = send(rows_name)
          rows.each do |row|
            record = self.find_or_initialize_by(id: row.id)
            row.aliased_attributes.each do |attr|
              record.send("#{attr}=", row.send(attr))
            end
            record.instance_variable_set(:@_skip_outbound_sync, true)
            record.save
            record.remove_instance_variable(:@_skip_outbound_sync)
          end
        end

        # export one
        define_method("sync_#{rows_name.to_s.singularize}") do
          return if @_skip_outbound_sync
          row = self.class.send(rows_name).find(self.id)
          if destroyed?
            row.destroy
          else
            # TODO: separate by AttributeAssignment
            self.attributes_before_type_cast.each do |attr, value|
              row.send("#{attr}=", value)
            end
            row.save
          end
        end
      end
    end
  end
end
