
require 'spec_helper'

describe UUIDTools::UUID do

  before do
    input = "e4618518-cb9f-11e1-aa7c-14dae903e06a"
    @sql_out = "x'e4618518cb9f11e1aa7c14dae903e06a'"
    @param_out = "E4618518CB9F11E1AA7C14DAE903E06A"

    @uuid = UUIDTools::UUID.parse input
  end

  it 'adds methods to the UUID class' do
    [:quoted_id, :as_json, :to_param].each do |meth|
      @uuid.should respond_to(meth)
    end
  end

  describe '#quoted_id' do
    it 'returns the SQL binary representation for the uuid' do
      @uuid.quoted_id.should eql(@sql_out)
    end
  end

  describe '#as_json' do
    it 'returns the uppercase hexdigest' do
      @uuid.as_json.should eql(@param_out)
    end
  end

  describe '#to_param' do
    it 'also returns the uppercase hexdigest' do
      @uuid.to_param.should eql(@param_out)
    end
  end
    
end
