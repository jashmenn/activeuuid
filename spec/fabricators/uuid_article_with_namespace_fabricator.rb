Fabricator(:uuid_article_with_namespace) do
  title { Forgery::LoremIpsum.word }
  body { Forgery::LoremIpsum.sentence }
end
