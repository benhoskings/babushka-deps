meta :repo do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def ref_data_regexp
    # Example: "83a90415670ec7ae4690d58563be628c73900716 e817f54d3e9a2d982b16328f8d7f0fbfcd7433f7 refs/heads/master"
    /\A([\da-f]{40}) ([\da-f]{40}) refs\/[^\/]+\/(.+)\z/
  end
end
