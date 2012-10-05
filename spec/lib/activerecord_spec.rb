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