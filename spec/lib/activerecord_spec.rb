require 'spec_helper'

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