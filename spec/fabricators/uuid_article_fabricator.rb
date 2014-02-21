Fabricator(:uuid_article) do
  title { Forgery::LoremIpsum.word }
  body { Forgery::LoremIpsum.sentence }
  tags(count: 5)
end
