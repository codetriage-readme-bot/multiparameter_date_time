require 'active_support/concern'
require 'american_date'
require 'is_valid_multiparameter_date_time_validator'

module MultiparameterDateTime
  extend ActiveSupport::Concern
  VALID_DATE_FORMAT = /\A((\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4})\z|(\d{4}-\d{1,2}-\d{1,2})\z)/
  VALID_STANDARD_TIME_FORMAT = /\A[0]*([1-9]|1[0-2]):\d{2}(:\d{2})?\s*([apAP][mM])?\s*([A-Z]{3,5})?\Z/
  VALID_MILITARY_TIME_FORMAT = /\A[0]*([0-9]|1[0-9]|2[0-3]):\d{2}(:\d{2})?\s*([A-Z]{3,5})?\Z/

  DEFAULT_DATE_FORMAT = '%-m/%-d/%0Y'
  DEFAULT_TIME_FORMAT = '%-I:%0M %P'

  mattr_writer :date_format, :time_format

  def self.date_format
    @@date_format ||= DEFAULT_DATE_FORMAT
  end

  def self.time_format
    @@time_format ||= DEFAULT_TIME_FORMAT
  end

  module ClassMethods
    def multiparameter_date_time(attribute_name)
      date_attribute = :"#{attribute_name}_date_part"
      time_attribute = :"#{attribute_name}_time_part"

      date_ivar_name = "@#{date_attribute}"
      time_ivar_name = "@#{time_attribute}"

      date_part_setter = :"#{date_attribute}="
      time_part_setter = :"#{time_attribute}="

      define_method "#{attribute_name}=" do |date_time_input|
        case date_time_input
        when Date, Time, DateTime
          if date_time_input.respond_to?(:in_time_zone)
            begin
              date_time_input = date_time_input.in_time_zone
            rescue ArgumentError
            end
          end
          write_attribute_for_multiparameter_date_time(attribute_name, date_time_input)
        when String
          iso8601 = Time.iso8601(date_time_input).in_time_zone(Time.zone) rescue nil
          if iso8601
            write_attribute_for_multiparameter_date_time(attribute_name, iso8601)
          else
            date_part, time_part = date_time_input.split(' ', 2)
            parsed_date_part = Date.parse(date_part) rescue nil
            if time_part.nil? && parsed_date_part
              write_attribute_for_multiparameter_date_time(
                attribute_name,
                parsed_date_part.in_time_zone)
            else
              public_send(date_part_setter, date_part)
              public_send(time_part_setter, time_part)
            end
          end
        end
      end

      define_method date_part_setter do |date_string|
        instance_variable_set(date_ivar_name, date_string)
        time_string = send(time_attribute)
        set_combined_datetime(attribute_name, date_string, time_string)
      end

      define_method time_part_setter do |time_string|
        instance_variable_set(time_ivar_name, time_string)
        date_string = send(date_attribute)
        set_combined_datetime(attribute_name, date_string, time_string)
      end

      define_method time_attribute do
        if instance_variable_defined?(time_ivar_name)
          instance_variable_get(time_ivar_name)
        else
          time = public_send(attribute_name)
          return nil if time.nil? || time == :incomplete

          time.strftime(MultiparameterDateTime.time_format)
        end
      end

      define_method date_attribute do
        if instance_variable_defined?(date_ivar_name)
          instance_variable_get(date_ivar_name)
        else
          date = public_send(attribute_name)
          return nil if date.nil? || date == :incomplete
          date.strftime(MultiparameterDateTime.date_format)
        end
      end
    end
  end

  private

  def set_combined_datetime(name, date_string, time_string)
    if date_string =~ MultiparameterDateTime::VALID_DATE_FORMAT && (time_string =~ MultiparameterDateTime::VALID_STANDARD_TIME_FORMAT || time_string =~ VALID_MILITARY_TIME_FORMAT)
      begin
        write_attribute_for_multiparameter_date_time(
          name, Time.zone.parse("#{date_string} #{time_string}")
        )
      rescue ArgumentError
        write_attribute_for_multiparameter_date_time(name, :incomplete)
      end

    elsif date_string.blank? && time_string.blank?
      write_attribute_for_multiparameter_date_time(name, nil)
    else
      write_attribute_for_multiparameter_date_time(name, :incomplete)
    end
  end

  def write_attribute_for_multiparameter_date_time(attribute_name, value)
    write_attribute(attribute_name, value)
  rescue NoMethodError
    instance_variable_set("@#{attribute_name}", value)
  end
end
