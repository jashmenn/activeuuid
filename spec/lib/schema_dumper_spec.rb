require 'spec_helper'

describe ActiveRecord::SchemaDumper do
  let!(:connection) { ActiveRecord::Base.connection }
  let(:table_name) { :test_uuid_pk_dump }

  before do
    connection.drop_table(table_name) if connection.table_exists?(table_name)
    connection.create_table table_name, :id => false do |t|
      t.uuid :id, :primary_key => true
    end
  end

  after do
    connection.drop_table table_name
  end

  context 'dump' do
    let(:dump) do
      stream = StringIO.new
      ActiveRecord::SchemaDumper::dump(connection, stream)
      stream.string.split("\n")
    end
    it 'should generate a dump' do
      dump.should be_a_kind_of(Array)
    end
    context 'schema definition' do
      let(:create_table_line) { dump.index{|l| /create_table "#{table_name}", :id =\> false/ =~ l} }
      it 'should have a table creation statement' do
        create_table_line.should be_a_kind_of(Numeric)
      end
      context 'table' do
        it 'should have a uuid primary key' do
          create_table_line.should_not be_nil
          dump[create_table_line+1].should match(/t.uuid *"id", *:primary_key =\> true/)
        end
      end
    end
  end
end
