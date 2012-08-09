require "active_support/concern"
require "american_date"

module MultiparameterDateTime
  extend ActiveSupport::Concern

  VALID_TIME_FORMAT = /\A\d?\d:\d{2}(:\d{2})?\s*([ap]m)?\s*([A-Z]{3,5})?\Z/
  VALID_DATE_FORMAT = /\A\d?\d\/\d?\d\/\d{4}|(\d{4}-\d{2}-\d{2})\Z/

  module ClassMethods
    def multiparameter_date_time(attribute_name)
      date_attribute = :"#{attribute_name}_date_part"
      time_attribute = :"#{attribute_name}_time_part"

      date_ivar_name = "@#{date_attribute}"
      time_ivar_name = "@#{time_attribute}"

      date_part_setter = :"#{date_attribute}="
      time_part_setter = :"#{time_attribute}="

      define_method "#{attribute_name}=" do |date_time_input|
        date_time_input = date_time_input.to_time_in_current_zone if date_time_input.respond_to?(:to_time_in_current_zone)
        if date_time_input.is_a?(String)
          iso8601 = Time.iso8601(date_time_input).in_time_zone(Time.zone) rescue nil
          if iso8601
            write_attribute_for_multiparameter_date_time(attribute_name, iso8601)
          else
            date_part, time_part = date_time_input.split(" ", 2)
            parsed_date_part = Date.parse(date_part) rescue nil
            if time_part.nil? && parsed_date_part
              write_attribute_for_multiparameter_date_time(
                attribute_name,
                parsed_date_part.to_time_in_current_zone)
            else
              public_send(date_part_setter, date_part)
              public_send(time_part_setter, time_part)
            end
          end
        else
          write_attribute_for_multiparameter_date_time(attribute_name, date_time_input)
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

          time.strftime("%-I:%M %P")
        end
      end

      define_method date_attribute do
        if instance_variable_defined?(date_ivar_name)
          instance_variable_get(date_ivar_name)
        else
          date = public_send(attribute_name)
          return nil if date.nil? || date == :incomplete
          date.strftime("%-m/%-d/%Y")
        end
      end
    end
  end

  private

  def set_combined_datetime(name, date_string, time_string)
    if date_string =~ MultiparameterDateTime::VALID_DATE_FORMAT && time_string =~ MultiparameterDateTime::VALID_TIME_FORMAT
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
