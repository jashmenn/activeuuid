require 'spec_helper'

describe ActiveRecord::Base do
  context '.connection' do
    let!(:connection) { ActiveRecord::Base.connection }
    let(:table_name) { :test_uuid_field_creation }
    
    before :each do
      connection.create_table table_name
      connection.table_exists?(table_name).should be_true
    end
    
    after :each do
      connection.drop_table table_name
    end
    
    context '#add_column' do
      it 'support adding uuid column' do
        connection.add_column table_name, :uuid_col, :uuid
        connection.column_exists?(table_name, :uuid_col).should be_true
        columns = connection.columns(table_name)
        col = (columns.select {|c| c.name.to_sym == :uuid_col }).first
        col.should_not be_nil
      
        spec_for_adapter do |adapters|
          adapters.sqlite { col.sql_type.should == 'uuid' }
          adapters.mysql2 do
            col.sql_type.should == 'binary(16)'
            col.type.should == :binary
            col.respond_to? :string_to_binary
          end
        end
      end
    end
    
    context '#change_column' do
      before :each do
        connection.add_column table_name, :binary_col, :binary, :limit => 16
      end
      
      it 'support changing type from binary to uuid' do
        col = (connection.columns(table_name).select {|c| c.name.to_sym == :binary_col}).first
        col.should_not be_nil
        spec_for_adapter do |adapters|
          adapters.mysql2 do 
            col.type.should == :binary
            col.sql_type.should == 'tinyblob'
          end
        end
        
        connection.change_column table_name, :binary_col, :uuid
        
        col = (connection.columns(table_name).select {|c| c.name.to_sym == :binary_col}).first
        col.should_not be_nil
        spec_for_adapter do |adapters|
          adapters.mysql2 do 
            col.type.should == :binary
            col.sql_type.should == 'binary(16)'
          end
        end
      end
    end
    
  end
end

describe Article do
  let!(:article) { Fabricate :article }
  let(:id) { article.id }
  let(:model) { Article }

  context 'existance' do
    specify { article.id.should be_a Integer }
    it "should create record" do
      model.all.should == [article]
      model.first.should == article
    end
  end

  context '.find' do
    specify { model.find(id).should == article }
  end

  context '.where' do
    specify { model.where(:id => id).first.should == article }
  end

  context '.destroy' do
    specify { article.delete.should be_true }
    specify { article.destroy.should be_true }
  end
end

describe UuidArticle do
  let!(:article) { Fabricate :uuid_article }
  let(:id) { article.id }
  let(:model) { UuidArticle }

  specify { model.primary_key.should == 'id' }

  context 'existance' do
    specify { article.id.should be_a UUIDTools::UUID }
    it "should create record" do
      model.all.should == [article]
      model.first.should == article
    end
  end

  context '.find' do
    specify { model.find(article).should == article }
    specify { model.find(id).should == article }
    specify { model.find(id.to_s).should == article }
    specify { model.find(id.raw).should == article }
  end

  context '.where' do
    specify { model.where(:id => article).first.should == article }
    specify { model.where(:id => id).first.should == article }
    specify { model.where(:id => id.to_s).first.should == article }
    specify { model.where(:id => id.raw).first.should == article }
  end

  context '.destroy' do
    specify { article.delete.should be_true }
    specify { article.destroy.should be_true }
  end
end