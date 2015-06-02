require 'spec_helper'

describe UUIDTools::UUID do
  let(:input) { "e4618518-cb9f-11e1-aa7c-14dae903e06a" }
  let(:hex) { "E4618518CB9F11E1AA7C14DAE903E06A" }
  let(:uuid) { described_class.parse input }

  context 'instance methods' do
    subject { uuid }
    let(:sql_out) { "x'e4618518cb9f11e1aa7c14dae903e06a'" }

    its(:quoted_id) {should == sql_out}
    its(:as_json) {should == uuid.to_s}
    its(:to_param) {should == uuid.to_s}
    its(:next) {should be_a(described_class)}
  end

  describe '.serialize' do
    subject { described_class }
    let(:raw) { uuid.raw }

    specify { subject.serialize(uuid).should == uuid }
    specify { subject.serialize(input).should == uuid }
    specify { subject.serialize(hex).should == uuid }
    specify { subject.serialize(raw).should == uuid }
    specify { subject.serialize(nil).should be_nil }
    specify { subject.serialize('').should be_nil }
    specify { subject.serialize(5).should be_nil }
  end
end
