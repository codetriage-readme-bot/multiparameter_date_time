require 'spec_helper'

require 'multiparameter_date_time'
require 'informal'
require 'active_support/core_ext/time/zones'
require 'is_valid_multiparameter_date_time_validator'

describe IsValidMultiparameterDateTimeValidator do
  before do
    Time.zone = "US/Eastern"
  end

  with_model :ModelWithDatetime do
    table do |t|
      t.datetime :foo
    end

    model do
      include MultiparameterDateTime
      multiparameter_date_time :foo
      validates :foo, is_valid_multiparameter_date_time: true, allow_blank: true
    end
  end

  describe "#validate_each" do
    subject { record }
    let(:record) do
      ModelWithDatetime.new(
        foo_date_part: date_string,
        foo_time_part: time_string
      )
    end

    let(:bad_format_error) do
      "Please enter a valid date and time using the following formats: 1/29/2000, 5:15 pm"
    end
    let(:missing_time_error) { "Please enter a time." }
    let(:missing_date_error) { "Please enter a date." }

    before { record.valid? }

    context "with valid date" do
      let(:date_string) { "01/01/2001" }

      context "with valid time" do
        let(:time_string) { "12:31pm" }
        it "should not have an error" do
          record.errors[:foo].should be_empty
        end
      end

      context "with invalid time" do
        let(:time_string) { "asdf" }

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end

      [" ", nil].each do |time_value|
        context "with time = #{time_value.inspect}" do
          let(:time_string) { time_value }
          it "should show the missing time error" do
            record.errors[:foo].should == [missing_time_error]
          end
        end
      end
    end

    context "with invalid date" do
      let(:date_string) { "asdf" }

      context "with valid time" do
        let(:time_string) { "12:31pm" }

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end

      context "with invalid time" do
        let(:time_string) { "asdf" }

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end

      [" ", nil].each do |time_value|
        context "with time = #{time_value.inspect}" do
          let(:time_string) { time_value }
          it "should show the bad format error" do
            record.errors[:foo].should == [bad_format_error]
          end
        end
      end
    end

    [" ", nil].each do |date_value|
      context "with date = #{date_value.inspect}" do
        let(:date_string) { date_value }

        context "with valid time" do
          let(:time_string) { "12:31pm" }

          it "should show the missing date error" do
            record.errors[:foo].should == [missing_date_error]
          end
        end

        context "with invalid time" do
          let(:time_string) { "asdf" }

          it "should show the bad format error" do
            record.errors[:foo].should == [bad_format_error]
          end
        end

        [" ", nil].each do |time_value|
          context "with time = #{time_value.inspect}" do
            let(:time_string) { time_value }
            it "should not have an error" do
              record.errors[:foo].should be_empty
            end
          end
        end
      end
    end

    context "when the datetime is set directly" do
      let(:record) { ModelWithDatetime.new(foo: Time.current) }
      it "should not have an error" do
        record.errors[:foo].should be_empty
      end
    end

    context "when the datetime is set directly to nil" do
      let(:record) { ModelWithDatetime.new(foo: nil) }
      it "should not have an error" do
        record.errors[:foo].should be_empty
      end
    end

    context "when nothing is set at all" do
      let(:record) { ModelWithDatetime.new }
      it "should not have an error" do
        record.errors[:foo].should be_empty
      end
    end

    context "with an impossible date" do
      context "set in parts" do
        let(:record) do
          ModelWithDatetime.new(foo_date_part: "19/19/1919", foo_time_part: "04:50pm")
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end

      context "set directly" do
        let(:record) do
          ModelWithDatetime.new(foo: "19/19/1919 04:50pm")
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end
    end

    context "with an impossible time" do
      context "set in parts" do
        let(:record) do
          ModelWithDatetime.new(foo_date_part: "01/01/2001", foo_time_part: "09:99pm")
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end

      context "set directly" do
        let(:record) do
          ModelWithDatetime.new(foo: "01/01/2001 09:99pm")
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [bad_format_error]
        end
      end
    end

    context "when the display format has been configured" do
      let(:date_string) { "asdf" }
      let(:time_string) { "foo" }

      context "when the date format is set" do
        before do
          MultiparameterDateTime.date_format = "%-m-%-e-%y"
          record.valid?
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [
            "Please enter a valid date and time using the following formats: 1-29-00, 5:15 pm"
          ]
        end

        after do
          MultiparameterDateTime.date_format = MultiparameterDateTime::DEFAULT_DATE_FORMAT
        end
      end

      context "when the time format is set" do
        let(:time_string) { "asdf" }

        before do
          MultiparameterDateTime.time_format = "%H%M hours"
          record.valid?
        end

        it "should show the bad format error" do
          record.errors[:foo].should == [
            "Please enter a valid date and time using the following formats: 1/29/2000, 1715 hours"
          ]
        end

        after do
          MultiparameterDateTime.time_format = MultiparameterDateTime::DEFAULT_TIME_FORMAT
        end
      end
    end
  end

  describe "accepts dates in a variety of formats" do
    ["2010-1-1", "02-01-1971", "4/4/92", "01/02/2001", "01/02/2001", "01.02.2011"].each do |format|
      context format do
        let(:date_string) { format }
        let(:time_string) { "12:00am" }
        let(:record) do
          ModelWithDatetime.new(foo_date_part: date_string, foo_time_part: time_string)
        end

        it "should be accepted" do
          record.should be_valid
        end
      end
    end
  end

  describe ".invalid_format_error_message" do
    subject { IsValidMultiparameterDateTimeValidator.invalid_format_error_message }

    it do
      should ==
        "Please enter a valid date and time using the following formats: 1/29/2000, 5:15 pm"
    end
  end
end
