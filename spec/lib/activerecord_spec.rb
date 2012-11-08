require 'spec_helper'

# describe ActiveRecord::Base do
#   context '.connection' do
#     let!(:connection) { ActiveRecord::Base.connection }
#     let(:table_name) { :test_uuid_field_creation }
    
#     before :each do
#       connection.create_table table_name
#       connection.table_exists?(table_name).should be_true
#     end
    
#     after :each do
#       connection.drop_table table_name
#     end
    
#     context '#add_column' do
#       it 'support adding uuid column' do
#         connection.add_column table_name, :uuid_col, :uuid
#         connection.column_exists?(table_name, :uuid_col).should be_true
#         columns = connection.columns(table_name)
#         col = (columns.select {|c| c.name.to_sym == :uuid_col }).first
#         col.should_not be_nil
      
#         spec_for_adapter do |adapters|
#           adapters.sqlite { col.sql_type.should == 'uuid' }
#           adapters.mysql2 do
#             col.sql_type.should == 'binary(16)'
#             col.type.should == :binary
#             col.respond_to? :string_to_binary
#           end
#         end
#       end
#     end
    
#     context '#change_column' do
#       before :each do
#         connection.add_column table_name, :binary_col, :binary, :limit => 16
#       end
      
#       it 'support changing type from binary to uuid' do
#         col = (connection.columns(table_name).select {|c| c.name.to_sym == :binary_col}).first
#         col.should_not be_nil
#         spec_for_adapter do |adapters|
#           adapters.mysql2 do 
#             col.type.should == :binary
#             col.sql_type.should == 'tinyblob'
#           end
#         end
        
#         connection.change_column table_name, :binary_col, :uuid
        
#         col = (connection.columns(table_name).select {|c| c.name.to_sym == :binary_col}).first
#         col.should_not be_nil
#         spec_for_adapter do |adapters|
#           adapters.mysql2 do 
#             col.type.should == :binary
#             col.sql_type.should == 'binary(16)'
#           end
#         end
#       end
#     end
    
#   end
# end

describe Article do
  let!(:article) { Fabricate :article }
  let(:id) { article.id }
  let(:model) { Article }
  subject { model }

  context 'model' do
    its(:all) { should == [article] }
    its(:first) { should == article }
  end

  context 'existance' do
    subject { article }
    its(:id) { should be_a Integer }
  end

  context '.find' do
    specify { model.find(id).should == article }
  end

  context '.where' do
    specify { model.where(id: id).first.should == article }
  end

  context '#destroy' do
    subject { article }
    its(:delete) { should be_true }
    its(:destroy) { should be_true }
  end
end

describe UuidArticle do
  let!(:article) { Fabricate :uuid_article }
  let!(:id) { article.id }
  let(:model) { described_class }
  subject { model }

  context 'model' do
    its(:primary_key) { should == 'id' }
    its(:all) { should == [article] }
    its(:first) { should == article }
  end

  context 'existance' do
    subject { article }
    its(:id) { should be_a UUIDTools::UUID }
  end

  context '.find' do
    specify { model.find(article).should == article }
    specify { model.find(id).should == article }
    specify { model.find(id.to_s).should == article }
    specify { model.find(id.raw).should == article }
  end

  context '.where' do
    specify { model.where(id: article).first.should == article }
    specify { model.where(id: id).first.should == article }
    specify { model.where(id: id.to_s).first.should == article }
    specify { model.where(id: id.raw).first.should == article }
  end

  context '#destroy' do
    subject { article }
    its(:delete) { should be_true }
    its(:destroy) { should be_true }
  end

  context '#reload' do
    subject { article }
    its(:'reload.id') { should == id }
    specify { subject.reload(:select => :another_uuid).id.should == id }
  end

  context 'columns' do
    [:id, :another_uuid].each do |column|
      context column do
        subject { model.columns_hash[column.to_s] }
        its(:type) { should == :uuid }
      end
    end
  end

  context 'typecasting' do
    let(:uuid) { UUIDTools::UUID.random_create }
    let(:string) { uuid.to_s }
    context 'primary' do
      before { article.id = string }
      specify do
        article.id.should == uuid
        article.id_before_type_cast.should == string
      end
      specify do
        article.id_before_type_cast.should == string
        article.id.should == uuid
      end
    end

    context 'non-primary' do
      before { article.another_uuid = string }
      specify do
        article.another_uuid.should == uuid
        article.another_uuid_before_type_cast.should == string
      end
      specify do
        article.another_uuid_before_type_cast.should == string
        article.another_uuid.should == uuid
      end
      specify do
        article.save
        article.reload
        article.another_uuid_before_type_cast.should == string
        article.another_uuid.should == uuid
      end
    end
  end
end