Fabricator(:article) do
  title { Forgery::LoremIpsum.word }
  body { Forgery::LoremIpsum.sentence }
end
