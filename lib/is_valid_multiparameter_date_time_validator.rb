require 'active_model/validator'

class IsValidMultiparameterDateTimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    date_part_key = :"#{attribute}_date_part"
    date_value = record.public_send(date_part_key)

    time_part_key = :"#{attribute}_time_part"
    time_value = record.public_send(time_part_key)

    return if !options[:required] && date_value.blank? && time_value.blank?

    if date_value.blank? && time_value.blank?
      message = "Please enter a date and time for the #{record.class.name.titleize.downcase}."
      record.errors.add(attribute, message)
    elsif date_invalid?(date_value) || time_invalid?(time_value)
      record.errors.add(attribute, self.class.invalid_format_error_message)
    elsif date_value.blank?
      message = record.errors.generate_message(date_part_key, :blank, default: 'Please enter a date.')
      record.errors.add(attribute, message)
    elsif time_value.blank?
      message = record.errors.generate_message(time_part_key, :blank, default: 'Please enter a time.')
      record.errors.add(attribute, message)
    else
      begin
        Date.parse(date_value)
        Time.zone.parse("#{date_value} #{time_value}")
        Time.zone.parse(time_value)
      rescue ArgumentError
        record.errors.add(attribute, self.class.invalid_format_error_message)
      end
    end
  end

  def self.invalid_format_error_message
    date_time = Time.zone.parse('1/29/2000 5:15pm')
    date_string = date_time.strftime(MultiparameterDateTime.date_format)
    time_string = date_time.strftime(MultiparameterDateTime.time_format)

    "Please enter a valid date and time using the following formats: #{date_string}, #{time_string}"
  end

  def time_invalid?(time_value)
    if time_value.present?
      time_invalid_standard = time_value !~ MultiparameterDateTime::VALID_STANDARD_TIME_FORMAT
      time_invalid_military = time_value !~ MultiparameterDateTime::VALID_MILITARY_TIME_FORMAT
      time_invalid_standard && time_invalid_military
    end
  end

  def date_invalid?(date_value)
    if date_value.present?
      date_invalid = date_value !~ MultiparameterDateTime::VALID_DATE_FORMAT
    end
  end
end
