class IsValidMultiparameterDateTimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    date_value = record.public_send(:"#{attribute}_date_part")
    time_value = record.public_send(:"#{attribute}_time_part")

    return if date_value.blank? && time_value.blank?

    if date_value.present?
      date_invalid = date_value !~ MultiparameterDateTime::VALID_DATE_FORMAT
    end

    if time_value.present?
      time_invalid = time_value !~ MultiparameterDateTime::VALID_TIME_FORMAT
    end

    if date_invalid || time_invalid
      record.errors.add(attribute, invalid_format_error_message)
    elsif date_value.blank?
      record.errors.add(attribute, "Please enter a date.")
    elsif time_value.blank?
      record.errors.add(attribute, "Please enter a time.")
    else
      attribute_value = record.public_send(:"#{attribute}_time_part")
      begin
        Time.zone.parse("#{date_value} #{time_value}")
        Time.zone.parse(attribute_value)
      rescue ArgumentError
        record.errors.add(attribute, invalid_format_error_message)
      end
    end
  end

  private

  def invalid_format_error_message
    date_time = Time.zone.parse("1/29/2000 5:15pm")
    date_string = date_time.strftime(MultiparameterDateTime.date_format)
    time_string = date_time.strftime(MultiparameterDateTime.time_format)

    "Please enter a valid date and time using the following formats: #{date_string}, #{time_string}"
  end
end
