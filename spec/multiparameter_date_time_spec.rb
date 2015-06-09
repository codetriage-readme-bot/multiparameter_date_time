require 'spec_helper'

require 'multiparameter_date_time'
require 'active_support/core_ext/time/zones'

describe MultiparameterDateTime do
  before do
    Time.zone = 'US/Eastern'
  end

  with_model :ModelWithDateTime do
    table do |t|
      t.datetime :foo
    end

    model do
      include MultiparameterDateTime
      multiparameter_date_time :foo
    end
  end

  class ActiveModelWithDateTime
    include ActiveModel::Model
    attr_accessor :foo
    include MultiparameterDateTime
    multiparameter_date_time :foo
  end

  %w[ModelWithDateTime ActiveModelWithDateTime].each do |model_name|
    let(:parent_model) { model_name.constantize }
    let(:subclass_model) { Class.new(parent_model) }

    [false, true].each do |use_subclass|
      let(:model) { use_subclass ? subclass_model : parent_model }

      context "for #{"a subclass of " if use_subclass}#{model_name}" do
        let(:record) do
          model.new(foo_date_part: foo_date_part, foo_time_part: foo_time_part)
        end

        subject { record }

        describe "when a value is present" do
          let(:record) { model.new(foo: Time.zone.parse('1/2/2003 04:05pm')) }
          it 'assigns date_part' do
            expect(subject.foo_date_part).to eq '1/2/2003'
          end

          it 'assigns time_part' do
            expect(subject.foo_time_part).to eq '4:05 pm'
          end
        end

        describe "setting a valid date and time" do
          let(:foo_date_part) { '01/02/2000' }
          let(:foo_time_part) { '9:30 pm EST' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to a DateTime object" do
            subject.foo.should == Time.zone.parse('1/2/2000 9:30 pm')
          end

          it "has the original date input" do
            subject.foo_date_part.should == '01/02/2000'
          end

          it "has the original time input" do
            subject.foo_time_part.should == '9:30 pm EST'
          end
        end

        describe "setting an invalid date" do
          let(:foo_date_part) { 'bad input' }
          let(:foo_time_part) { '9:30 pm' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date" do
            subject.foo_date_part.should == 'bad input'
          end

          it "has the original time input" do
            subject.foo_time_part.should == '9:30 pm'
          end
        end

        describe "setting a impossible date" do
          let(:foo_date_part) { '99/99/9999' }
          let(:foo_time_part) { '12:30 pm' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date" do
            subject.foo_date_part.should == '99/99/9999'
          end

          it "has the original time" do
            subject.foo_time_part.should == '12:30 pm'
          end
        end

        describe "setting an invalid time" do
          let(:foo_date_part) { '01/02/2000' }
          let(:foo_time_part) { 'bad input' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date input" do
            subject.foo_date_part.should == '01/02/2000'
          end

          it "has the original time input" do
            subject.foo_time_part.should == "bad input"
          end
        end

        describe "setting a impossible time" do
          let(:foo_date_part) { '01/02/2000' }
          let(:foo_time_part) { '99:99pm' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date input" do
            subject.foo_date_part.should == '01/02/2000'
          end

          it "has the original time input" do
            subject.foo_time_part.should == '99:99pm'
          end
        end

        describe "setting a date but not a time" do
          let(:record) { model.new(foo_date_part: '01/01/2000') }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date" do
            subject.foo_date_part.should == '01/01/2000'
          end

          it "has the nil for the time input" do
            subject.foo_time_part.should == nil
          end
        end

        describe "setting a time but not a date" do
          let(:record) { model.new(foo_time_part: '12:30 pm') }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the nil for the date input" do
            subject.foo_date_part.should == nil
          end

          it "has the original time" do
            subject.foo_time_part.should == '12:30 pm'
          end
        end

        describe "setting incorrect time and date" do
          let(:record) { model.new(foo_time_part: 'qwer',
                                   foo_date_part: 'asdf') }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to :incomplete" do
            subject.foo.should == :incomplete
          end

          it "has the original date" do
            subject.foo_date_part.should == 'asdf'
          end

          it "has the original time input" do
            subject.foo_time_part.should == 'qwer'
          end
        end

        describe "setting neither time nor a date" do
          let(:record) { model.new(foo_time_part: '',
                                   foo_date_part: '') }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "has nil for the attribute" do
            subject.foo.should == nil
          end

          it "has the original date" do
            subject.foo_date_part.should == ''
          end

          it "has the original time input" do
            subject.foo_time_part.should == ''
          end
        end

        describe "setting a DateTime directly" do
          let(:record) { model.new(foo: Time.zone.parse("#{foo_date_part} #{foo_time_part}")) }
          let(:foo_date_part) { '01/02/2000' }
          let(:foo_time_part) { '12:30 pm' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to a DateTime object" do
            subject.foo.should == Time.zone.parse('01/02/2000 12:30 pm')
          end

          it "has the original date" do
            subject.foo_date_part.should == '1/2/2000'
          end

          it "has the original time input" do
            subject.foo_time_part.should == '12:30 pm'
          end
        end

        describe "setting a String directly" do
          context "When the string contains a date and time" do
            let(:record) { model.new(foo: "#{foo_date_part} #{foo_time_part}") }
            let(:foo_date_part) { '01/01/2000' }
            let(:foo_time_part) { '12:30 pm' }

            it "doesn't raise an exception" do
              expect { subject }.not_to raise_exception
            end

            it "sets the attribute to a DateTime object" do
              subject.foo.should == Time.zone.parse('01/01/2000 12:30pm')
            end

            it "has the original date" do
              subject.foo_date_part.should == '01/01/2000'
            end

            it "has the original time" do
              subject.foo_time_part.should == '12:30 pm'
            end
          end

          context "When the string contains an iso8601 datetime" do
            let(:record) { model.new(foo: '2011-12-03T01:00:00Z') }

            it "doesn't raise an exception" do
              expect { subject }.not_to raise_exception
            end

            it "sets the attribute to a DateTime object with the correct EST time" do
              subject.foo.should == Time.zone.parse('12/2/2011 8:00 pm')
            end

            it "has a date" do
              subject.foo_date_part.should == '12/2/2011'
            end

            it "has a time" do
              subject.foo_time_part.should == '8:00 pm'
            end
          end

          context "When the string contains only a date" do
            let(:record) { model.new(foo: "#{foo_date_part}") }
            let(:foo_date_part) { '01/01/2000' }

            it "doesn't raise an exception" do
              expect { subject }.not_to raise_exception
            end

            it "sets the attribute to a DateTime object" do
              subject.foo.should == Time.zone.parse('01/01/2000 12:00am')
            end

            it "has the original date" do
              subject.foo_date_part.should == '1/1/2000'
            end

            it "has midnight for the time input" do
              subject.foo_time_part.should == '12:00 am'
            end
          end
        end

        describe "setting a Date directly" do
          let(:record) { model.new(foo: Date.parse(foo_date_part)) }

          let(:foo_date_part) { '01/01/2000' }

          it "doesn't raise an exception" do
            expect { subject }.not_to raise_exception
          end

          it "sets the attribute to a DateTime object in the current time zone" do
            subject.foo.should == Time.zone.parse('01/01/2000 12:00 am')
          end

          it "has the original date" do
            subject.foo_date_part.should == '1/1/2000'
          end

          it "has midnight for the time input" do
            subject.foo_time_part.should == '12:00 am'
          end
        end

        describe "setting to nil" do
          it "is nil" do
            record = ModelWithDateTime.new
            record.foo = Time.current
            record.foo = nil
            expect(record.foo).to eq nil
          end
        end

        describe "configuring the datetime format" do
          let(:record) { model.new(foo: Time.zone.parse('01/09/2000 1:30 pm')) }

          context "when the date format is set" do
            before do
              MultiparameterDateTime.date_format = '%-m-%-e-%0y'
            end

            it "should format the date properly" do
              subject.foo_date_part.should == '1-9-00'
            end

            it "should use the default format for the time" do
              subject.foo_time_part.should == '1:30 pm'
            end

            after do
              MultiparameterDateTime.date_format = MultiparameterDateTime::DEFAULT_DATE_FORMAT
            end
          end

          context "when the time format is set" do
            before do
              MultiparameterDateTime.time_format = '%H%M hours'
            end

            it "should format the time properly" do
              subject.foo_time_part.should == '1330 hours'
            end

            it "should use the default format for the date" do
              subject.foo_date_part.should == '1/9/2000'
            end

            after do
              MultiparameterDateTime.time_format = MultiparameterDateTime::DEFAULT_TIME_FORMAT
            end
          end
        end

        describe 'using a custom date string formatter' do
          let(:foo_date_part) { '1/12/15' }
          let(:foo_time_part) { '9:30 pm EST' }

          context 'when the date string formatter is nil' do
            it 'parses the unmodified date string' do
              MultiparameterDateTime.date_string_formatter = nil
              expect(Time.zone).to receive(:parse)
                .with("#{foo_date_part} #{foo_time_part}")

              model.new(foo_date_part: foo_date_part, foo_time_part: foo_time_part)
            end
          end

          context 'when the date string formatter is present' do
            before do
              class TestFormatter
                def self.format(date_string)
                  '12/31/1995'
                end
              end

              MultiparameterDateTime.date_string_formatter = TestFormatter
            end

            after do
              MultiparameterDateTime.date_string_formatter = nil
            end

            it 'uses a formatted date string' do
              expect(Time.zone).to receive(:parse)
                .with("#{'12/31/1995'} #{foo_time_part}")

              model.new(foo_date_part: foo_date_part, foo_time_part: foo_time_part)
            end
          end
        end
      end
    end
  end
end
