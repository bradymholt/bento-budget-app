json.array!(@foos) do |foo|
  json.extract! foo, 
  json.url foo_url(foo, format: :json)
end
