Fabricator(:uuid_article_with_natural_key) do
  title { Forgery::LoremIpsum.word }
  body { Forgery::LoremIpsum.sentence }
end
