require 'acclaim/option'

describe Acclaim::Option do

  let(:key) { :key }
  let(:args) { [] }
  let(:block) { nil }
  subject { Acclaim::Option.new key, *args, &block }

  describe '#initialize' do
    it 'should use the given key' do
      subject.key.should == key
    end

    context 'when given multiple strings' do
      let(:switches) { %w(-s --switch) }
      let(:description) { 'Description' }
      let(:args) { [switches, description].flatten! }

      it 'should find the switches' do
        subject.names.should == switches
      end

      it 'should find the description' do
        subject.description.should == description
      end
    end

    context 'when not given a class' do
      it "should use String as the option's type" do
        subject.type.should == String
      end
    end

    context 'when given a class' do
      let(:type) { Integer }
      let(:args) { [type] }

      it "should use it as the option's type" do
        subject.type.should == type
      end
    end

    context 'when given an additional parameter hash' do
      let(:hash) { {} }
      let(:args) { [hash] }

      context 'that does not specify an arity' do
        it 'should be a flag' do
          subject.should be_flag
        end
      end

      context 'that specifies an arity' do
        let(:hash) { { arity: arity } }

        context 'which requires one argument' do
          let(:arity) { Acclaim::Option::Arity.new 1 }

          it 'should not be a flag' do
            subject.should_not be_flag
          end
        end

        context 'which allows one optional argument' do
          let(:arity) { Acclaim::Option::Arity.new 0, 1 }

          it 'should not be a flag' do
            subject.should_not be_flag
          end
        end
      end

      context 'that does not specify a default value' do
        it 'should have a default value of nil' do
          subject.default.should be_nil
        end
      end

      context 'that specifies a default value' do
        let(:default) { 10 }
        let(:hash) { { default: default } }

        it 'should use the default value supplied' do
          subject.default.should == default
        end
      end

      context 'that does not specify whether the option is required' do
        it 'should not be required' do
          subject.should_not be_required
        end
      end

      context 'that specifies if the option is required' do
        let(:hash) { { required: required } }

        context 'as false' do
          let(:required) { false }

          it 'should not be required' do
            subject.should_not be_required
          end
        end

        context 'as true' do
          let(:required) { true }

          it 'should be required' do
            subject.should be_required
          end
        end
      end
    end

    context 'when not given a block' do
      it 'should not have a custom handler' do
        subject.handler.should be_nil
      end
    end

    context 'when given a block' do
      let(:block) { proc { |*args| p args } }

      it 'should have a custom handler' do
        subject.handler.should satisfy { |handler| Proc === handler }
      end
    end
  end

end
