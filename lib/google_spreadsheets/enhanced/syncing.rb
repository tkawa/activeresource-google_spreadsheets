module GoogleSpreadsheets
  module Enhanced
    module Syncing
      extend ActiveSupport::Concern

      REL_NAME_SPREADSHEET = 'http://schemas.google.com/spreadsheets/2006#spreadsheet'
      REL_NAME_ROW         = 'http://schemas.google.com/spreadsheets/2006#listfeed'

      included do
        class_attribute :synchronizers
        self.synchronizers = {}
      end

      module ClassMethods
        # === Example
        # class User < ActiveRecord::Base
        #   include GoogleSpreadsheets::Enhanced::Syncing
        #   sync_with :user_rows, spreadsheet_id: 'xxxx',
        #                         worksheet_title: 'users'
        #   after_commit :sync_user_row
        def sync_with(rows_name, options)
          options.assert_valid_keys(:spreadsheet_id, :worksheet_title, :class_name)
          options[:worksheet_title] ||= rows_name.to_s
          options[:class_name] ||= rows_name.to_s.classify
          synchronizer = Synchronizer.new(self, options[:class_name].safe_constantize, options[:spreadsheet_id], options[:worksheet_title])
          self.synchronizers = self.synchronizers.merge(rows_name => synchronizer) # not share parent class attrs

          # rows accessor
          define_singleton_method(rows_name) do
            synchronizer = self.synchronizers[rows_name]
            synchronizer.all_rows
          end

          # inbound sync all (import)
          define_singleton_method("sync_with_#{rows_name}") do |options = {}|
            synchronizer = self.synchronizers[rows_name]
            synchronizer.sync_with_rows(options)
          end

          # outbound sync one (export)
          define_method("sync_#{rows_name.to_s.singularize}") do
            synchronizer = self.class.synchronizers[rows_name]
            synchronizer.sync_row(self)
          end
        end
      end

      class Synchronizer
        attr_reader :record_class, :row_class, :spreadsheet_id, :worksheet_title

        def initialize(record_class, row_class, spreadsheet_id, worksheet_title)
          @record_class = record_class
          @row_class = row_class || default_class_for(REL_NAME_ROW)
          @spreadsheet_id = spreadsheet_id
          @worksheet_title = worksheet_title
        end

        def all_rows
          reflections = worksheet.class.reflections.values.find_all{|ref| ref.is_a?(LinkRelations::LinkRelationReflection) }
          if reflection = reflections.find{|ref| ref.klass == row_class }
            worksheet.send(reflection.name)
          elsif reflection = reflections.find{|ref| ref.options[:rel] == REL_NAME_ROW }
            worksheet.send(reflection.name, as: row_class.to_s)
          else
            raise "Reflection for #{row_class.to_s} not found."
          end
        end

        def sync_with_rows(options)
          reset
          records = all_rows.map do |row|
            record_class.find_or_initialize_by(id: row.id).tap do |record|
              row.aliased_attributes.each do |attr|
                value = row.send(attr)
                if options[:include_blank] || value.present?
                  record.send("#{attr}=", value)
                end
              end
            end
          end
          skipping_outbound_sync_of(records) do |records_with_skipped_outbound|
            transaction_if_possible(record_class) do
              records_with_skipped_outbound.each(&:save)
            end
          end
        end

        def sync_row(record)
          return if record.instance_variable_defined?(:@_skip_outbound_sync) &&
                    record.instance_variable_get(:@_skip_outbound_sync)
          row = all_rows.find(record.id)
          if record.destroyed?
            row.destroy
          else
            # TODO: separate by AttributeAssignment
            row.aliased_attributes.each do |attr|
              value = (record.respond_to?(:attributes_before_type_cast) && record.attributes_before_type_cast[attr]) ||
                      record.send(attr)
              row.send("#{attr}=", value)
            end
            row.save
          end
        end

        def worksheet
          @worksheet ||= default_class_for(REL_NAME_SPREADSHEET)
                           .find(spreadsheet_id)
                           .worksheets
                           .find_by!(title: worksheet_title)
        end

        def reset
          @worksheet = nil
          self
        end

        private
        def default_class_for(rel_name)
          LinkRelations.class_name_mappings[rel_name].classify.constantize
        end

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
end
