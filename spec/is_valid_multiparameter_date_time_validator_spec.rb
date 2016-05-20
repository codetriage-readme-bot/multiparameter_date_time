require 'spec_helper'

require 'multiparameter_date_time'
require 'is_valid_multiparameter_date_time_validator'

describe IsValidMultiparameterDateTimeValidator do
  before do
    Time.zone = 'US/Eastern'
  end

  with_model :ModelWithDatetime do
    table do |t|
      t.datetime :foo
    end

    model do
      include MultiparameterDateTime
      multiparameter_date_time :foo
      validates :foo, is_valid_multiparameter_date_time: true
    end
  end

  shared_examples_for 'a valid time' do
    it 'does not have an error' do
      record.valid?
      expect(record.errors[:foo]).to be_empty
    end
  end

  shared_examples_for 'a badly formatted date or time' do
    it 'shows the bad format error' do
      record.valid?
      expect(record.errors[:foo]).to eq [bad_format_error]
    end
  end

  describe '#validate_each' do
    subject { record }
    let(:record) do
      ModelWithDatetime.new(
        foo_date_part: date_string,
        foo_time_part: time_string
      )
    end

    let(:bad_format_error) do
      'Please enter a valid date and time using the following formats: 1/29/2000, 5:15 pm'
    end
    let(:missing_time_error) { 'Please enter a time.' }
    let(:missing_date_error) { 'Please enter a date.' }

    context 'with valid date' do
      let(:date_string) { '01/01/2001' }

      context 'with valid time in' do
        context 'military format' do
          context 'lots of zeros' do
            let(:time_string) { '00:00' }
            it_should_behave_like 'a valid time'
          end

          context 'last valid value' do
            let(:time_string) { '23:59' }
            it_should_behave_like 'a valid time'
          end

          context '1 pm' do
            let(:time_string) { '13:00' }
            it_should_behave_like 'a valid time'
          end
        end

        context 'standard format' do
          let(:time_string) { '12:31pm' }
          it_should_behave_like 'a valid time'

          context 'with a capital AM or PM' do
            let(:time_string) { '12:31 PM' }
            it_should_behave_like 'a valid time'
          end

          context 'without a space between the time and AM or PM' do
            let(:time_string) { '12:31AM' }
            it_should_behave_like 'a valid time'
          end

          context 'with no space and a mixed case aM or pM' do
            let(:time_string) { '12:31aM' }
            it_should_behave_like 'a valid time'
          end

          context 'with a space and a mixed case aM or pM' do
            let(:time_string) { '12:31 aM' }
            it_should_behave_like 'a valid time'
          end

          context 'with a space and a lower case am or pm' do
            let(:time_string) { '12:31 am' }
            it_should_behave_like 'a valid time'
          end
        end
      end

      context 'with invalid time in' do
        context 'military format' do
          context 'above 23:59' do
            let(:time_string) { '25:00' }
            it_should_behave_like 'a badly formatted date or time'
          end

          context 'with am or pm' do
            let(:time_string) { '23:00 am' }
            it_should_behave_like 'a badly formatted date or time'
          end
        end

        context 'standard format' do
          let(:time_string) { '90:00pm' }

          it_should_behave_like 'a badly formatted date or time'
        end
      end

      [' ', nil].each do |time_value|
        context "with time = #{time_value.inspect}" do
          let(:time_string) { time_value }

          context 'and default error messages' do
            it 'should show the missing time error' do
              record.valid?
              expect(record.errors[:foo]).to match_array [missing_time_error]
            end
          end
        end
      end

      [' ', nil].each do |time_value|
        context 'with I18n error messages' do
          let(:time_string) { time_value }

          before do
            translation = {
              activerecord: {
                errors: {
                  models: {
                    model_with_datetime: {
                      attributes: {
                        foo_time_part: { blank: 'custom error' } } } } } } }

            I18n.backend.store_translations :en, translation
          end

          it 'should show the I18n missing time error' do
            record.valid?
            expect(record.errors[:foo]).to match_array ['custom error']
          end
        end
      end
    end

    context 'with invalid date' do
      let(:date_string) { 'asdf' }

      context 'with valid time' do
        let(:time_string) { '12:31pm' }

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'with invalid time' do
        let(:time_string) { 'asdf' }

        it_should_behave_like 'a badly formatted date or time'
      end

      [' ', nil].each do |time_value|
        context "with time = #{time_value.inspect}" do
          let(:time_string) { time_value }
          it_should_behave_like 'a badly formatted date or time'
        end
      end
    end

    context 'with a date that has invalid format' do
      context 'with year has 5 digits' do
        let(:date_string) { '1/1/12012' }
        let(:time_string) { '12:31pm' }

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'with year has 1 digit' do
        let(:date_string) { '1/1/2' }
        let(:time_string) { '12:31pm' }

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'with month has 3 digits' do
        let(:date_string) { '100/1/2012' }
        let(:time_string) { '12:31pm' }

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'with day has 3 digits' do
        let(:date_string) { '10/100/2012' }
        let(:time_string) { '12:31pm' }

        it_should_behave_like 'a badly formatted date or time'
      end
    end

    [' ', nil].each do |date_value|
      context "with date = #{date_value.inspect}" do
        let(:date_string) { date_value }

        context 'with valid time' do
          let(:time_string) { '12:31pm' }

          it 'should show the missing date error' do
            record.valid?
            expect(record.errors[:foo]).to eq [missing_date_error]
          end
        end

        context 'with invalid time' do
          let(:time_string) { 'asdf' }

          it_should_behave_like 'a badly formatted date or time'
        end

        [' ', nil].each do |time_value|
          context "with time = #{time_value.inspect}" do
            let(:time_string) { time_value }
            it 'should not have an error' do
              record.valid?
              expect(record.errors[:foo]).to be_empty
            end
          end
        end
      end
    end

    [' ', nil].each do |date_value|
      context 'with valid time' do
        let(:date_string) { date_value }
        let(:time_string) { '12:31pm' }

        before do
          translation = {
            activerecord: {
              errors: {
                models: {
                  model_with_datetime: {
                    attributes: {
                      foo_date_part: { blank: 'custom error' } } } } } } }

          I18n.backend.store_translations :en, translation
        end

        context 'and I18n error messages' do
          it 'should show the missing date error' do
            record.valid?
            expect(record.errors[:foo]).to eq ['custom error']
          end
        end
      end
    end

    context 'when the datetime is set directly' do
      let(:record) { ModelWithDatetime.new(foo: Time.current) }
      it 'should not have an error' do
        record.valid?
        expect(record.errors[:foo]).to be_empty
      end
    end

    context 'when the datetime is set directly to nil' do
      let(:record) { ModelWithDatetime.new(foo: nil) }
      it 'should not have an error' do
        record.valid?
        expect(record.errors[:foo]).to be_empty
      end
    end

    context 'when nothing is set at all' do
      let(:record) { ModelWithDatetime.new }
      it 'should not have an error' do
        record.valid?
        expect(record.errors[:foo]).to be_empty
      end
    end

    context 'with an impossible date' do
      context 'set in parts' do
        let(:record) do
          ModelWithDatetime.new(foo_date_part: '19/19/1919', foo_time_part: '04:50pm')
        end

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'set directly' do
        let(:record) do
          ModelWithDatetime.new(foo: '19/19/1919 04:50pm')
        end

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'having a valid month but invalid day for that month' do
        context 'set in parts' do
          let(:record) do
            ModelWithDatetime.new(foo_date_part: '2/31/2015', foo_time_part: '04:50pm')
          end

          it_should_behave_like 'a badly formatted date or time'
        end

        context 'set directly' do
          let(:record) do
            ModelWithDatetime.new(foo: '2/31/2015 04:50pm')
          end

          it_should_behave_like 'a badly formatted date or time'
        end
      end
    end

    context 'with an impossible time' do
      context 'set in parts' do
        let(:record) do
          ModelWithDatetime.new(foo_date_part: '01/01/2001', foo_time_part: '09:99pm')
        end

        it_should_behave_like 'a badly formatted date or time'
      end

      context 'set directly' do
        let(:record) do
          ModelWithDatetime.new(foo: '01/01/2001 09:99pm')
        end

        it_should_behave_like 'a badly formatted date or time'
      end
    end

    context 'when the display format has been configured' do
      let(:date_string) { 'asdf' }
      let(:time_string) { 'foo' }

      context 'when the date format is set' do
        before do
          MultiparameterDateTime.date_format = '%-m-%-e-%0y'
        end

        it 'shows the bad format error' do
          record.valid?
          expect(record.errors[:foo]).to eq [
            'Please enter a valid date and time using the following formats: 1-29-00, 5:15 pm'
          ]
        end

        after do
          MultiparameterDateTime.date_format = MultiparameterDateTime::DEFAULT_DATE_FORMAT
        end
      end

      context 'when the time format is set' do
        let(:time_string) { 'asdf' }

        before do
          MultiparameterDateTime.time_format = '%H%M hours'
        end

        it 'shows the bad format error' do
          record.valid?
          expect(record.errors[:foo]).to eq [
            'Please enter a valid date and time using the following formats: 1/29/2000, 1715 hours'
          ]
        end

        after do
          MultiparameterDateTime.time_format = MultiparameterDateTime::DEFAULT_TIME_FORMAT
        end
      end
    end

    context 'parameter specifying whether the field is required' do
      context 'when nothing is set at all and the value is not required' do
        with_model :ModelWithDatetimeRequired do
          table do |t|
            t.datetime :foo
          end

          model do
            include MultiparameterDateTime
            multiparameter_date_time :foo
            validates :foo, is_valid_multiparameter_date_time: { required: false }
          end
        end

        let(:record) { ModelWithDatetimeRequired.new }

        it 'should show the missing datetime error' do
          record.valid?
          expect(record.errors[:foo]).to be_empty
        end
      end

      context 'when nothing is set at all and a value is required' do
        with_model :ModelWithDatetimeRequired do
          table do |t|
            t.datetime :foo
          end

          model do
            include MultiparameterDateTime
            multiparameter_date_time :foo
            validates :foo, is_valid_multiparameter_date_time: { required: true }
          end
        end

        let(:record) { ModelWithDatetimeRequired.new }

        it 'should show the missing datetime error' do
          record.valid?
          expect(record.errors[:foo]).to eq [
            'Please enter a date and time for the model with datetime required.'
          ]
        end
      end
    end
  end

  describe 'accepts dates in a variety of formats' do
    ['2010-1-1', '02-01-1971', '4/4/92', '01/02/2001', '01/02/2001', '01.02.2011'].each do |format|
      context format do
        let(:date_string) { format }
        let(:time_string) { '12:00am' }
        let(:record) do
          ModelWithDatetime.new(foo_date_part: date_string, foo_time_part: time_string)
        end

        it 'is accepted' do
          expect(record).to be_valid
        end
      end
    end
  end

  describe '.invalid_format_error_message' do
    it do
      expected_error = 'Please enter a valid date and time using the following formats: 1/29/2000, 5:15 pm'
      expect(described_class.invalid_format_error_message).to eq expected_error
    end
  end
end
