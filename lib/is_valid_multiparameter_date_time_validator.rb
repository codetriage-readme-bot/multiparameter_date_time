require 'active_model/validator'

class IsValidMultiparameterDateTimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    date_value = record.public_send(:"#{attribute}_date_part")
    time_value = record.public_send(:"#{attribute}_time_part")

    return if date_value.blank? && time_value.blank?

    if date_invalid?(date_value) || time_invalid?(time_value)
      record.errors.add(attribute, self.class.invalid_format_error_message)
    elsif date_value.blank?
      key = :"#{attribute}_date_part"
      message = record.errors.generate_message(key, :blank, default: 'Please enter a date.')
      record.errors.add(attribute, message)
    elsif time_value.blank?
      key = :"#{attribute}_time_part"
      message = record.errors.generate_message(key, :blank, default: 'Please enter a time.')
      record.errors.add(attribute, message)
    else
      attribute_value = record.public_send(:"#{attribute}_time_part")
      begin
        Time.zone.parse("#{date_value} #{time_value}")
        Time.zone.parse(attribute_value)
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
