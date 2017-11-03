require 'pghub/base'

class GithubAPIAssign
  module PullRequest
    include Connection
  end
end
