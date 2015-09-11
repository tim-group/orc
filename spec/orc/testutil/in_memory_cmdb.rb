class InMemoryCmdb
  def initialize(opts)
    @groups = opts[:groups]
  end

  def retrieve_application(spec)
    @groups["#{spec[:environment]}-#{spec[:application]}"]
  end
end
