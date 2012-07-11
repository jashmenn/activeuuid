 
require 'spec_helper'

describe ActiveUUID::UUIDSerializer do

  before do
    @input = "2d79b402-cba8-11e1-aa7c-14dae903e06a"
    @hex = "2D79B402CBA811E1AA7C14DAE903E06A"
    @uuid = UUIDTools::UUID.parse @input
    @raw = @uuid.raw
    @serializer = ActiveUUID::UUIDSerializer.new
  end

  describe '#load' do
    it 'returns a UUID type verbatim' do
       @serializer.load(@uuid).should eql(@uuid)
    end

    describe 'loads a given uuid' do
      it 'handles uuid string' do
        @serializer.load(@input).should eql(@uuid)
      end

      it 'handles uuid hexdigest string' do
        @serializer.load(@hex).should eql(@uuid)
      end

      it 'handles raw uuid data' do
        @serializer.load(@raw).should eql(@uuid)
      end
    end

    it 'returns nil for nil' do
      @serializer.load(nil).should be_nil
    end

    it 'throws an exception for other types' do
      lambda {
        @serializer.load(5)
      }.should raise_error(TypeError)
    end
      
  end

  describe '#dump' do
    it 'returns the raw value of a passed uuid' do
      @serializer.dump(@uuid).should eql(@raw)
    end

    describe 'loads a given uuid' do
      it 'handles uuid string' do
        @serializer.dump(@input).should eql(@raw)
      end

      it 'handles uuid hexdigest string' do
        @serializer.dump(@hex).should eql(@raw)
      end

      it 'handles raw uuid data' do
        @serializer.dump(@raw).should eql(@raw)
      end
    end

    it 'returns nil for nil' do
      @serializer.dump(nil).should be_nil
    end

    it 'throws an exception for other types' do
      lambda {
        @serializer.dump(5)
      }.should raise_error(TypeError)
    end

  end
end