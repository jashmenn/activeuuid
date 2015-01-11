require 'spec_helper'

describe ActiveRecord::Base do
  context '.connection' do
    let!(:connection) { ActiveRecord::Base.connection }
    let(:table_name) { :test_uuid_field_creation }

    before do
      connection.drop_table(table_name) if connection.table_exists?(table_name)
      connection.create_table(table_name)
    end

    after do
      connection.drop_table table_name
    end

    specify { connection.table_exists?(table_name).should be_truthy }

    context '#add_column' do
      let(:column_name) { :uuid_column }
      let(:column) { connection.columns(table_name).detect { |c| c.name.to_sym == column_name } }

      before { connection.add_column table_name, column_name, :uuid }

      specify { connection.column_exists?(table_name, column_name).should be_truthy }
      specify { column.should_not be_nil }

      it 'should have proper sql type' do
        spec_for_adapter do |adapters|
          adapters.sqlite3 { column.sql_type.should == 'binary(16)' }
          adapters.mysql2 { column.sql_type.should == 'binary(16)' }
          adapters.postgresql { column.sql_type.should == 'uuid' }
        end
      end
    end

    context '#change_column' do
      let(:column_name) { :string_col }
      let(:column) { connection.columns(table_name).detect { |c| c.name.to_sym == column_name } }

      before do
        connection.add_column table_name, column_name, :string
        spec_for_adapter do |adapters|
          adapters.sqlite3 { connection.change_column table_name, column_name, :uuid }
          adapters.mysql2 { connection.change_column table_name, column_name, :uuid }
          # adapters.postgresql { connection.change_column table_name, column_name, :uuid }
        end
      end

      it 'support changing type from string to uuid' do
        spec_for_adapter do |adapters|
          adapters.sqlite3 { column.sql_type.should == 'binary(16)' }
          adapters.mysql2 { column.sql_type.should == 'binary(16)' }
          adapters.postgresql { pending('postgresql can`t change column type to uuid') }
        end
      end
    end

  end
end

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
    its(:delete) { should be_truthy }
    its(:destroy) { should be_truthy }
  end

  context '#save' do
    subject { article }
    let(:array) { [1, 2, 3] }
    
    its(:save) { should be_truthy }

    context 'when change array field' do
      before { article.some_array = array }
      its(:save) { should be_truthy }      
    end
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

  context 'interpolation' do
    specify { model.where("id = :id", id: article.id) }
  end

  context 'batch interpolation' do
    before { model.update_all(["title = CASE WHEN id = :id THEN 'Passed' ELSE 'Nothing' END", id: article.id]) }
    specify { article.reload.title.should == 'Passed' }
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
    its(:delete) { should be_truthy }
    its(:destroy) { should be_truthy }
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

describe UuidArticleWithNaturalKey do
  let!(:article) { Fabricate :uuid_article_with_natural_key }
  let!(:id) { article.id }
  let!(:uuid) { UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE, article.title) }
  subject { article }
  context 'natural_key' do
    its(:id) { should == uuid }
  end
end

describe UuidArticleWithNamespace do
  let!(:article) { Fabricate :uuid_article_with_namespace }
  let!(:id) { article.id }
  let!(:namespace) { UuidArticleWithNamespace._uuid_namespace }
  let!(:uuid) { UUIDTools::UUID.sha1_create(namespace, article.title) }
  subject { article }
  context 'natural_key_with_namespace' do
    its(:id) { should == uuid }
  end
end

