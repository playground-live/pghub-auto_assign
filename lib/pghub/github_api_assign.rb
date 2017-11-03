require 'pghub/base'
require 'pghub/github_api_assign/organization'
require 'pghub/github_api_assign/pull_request'

class GithubAPIAssign < GithubAPI
  include GithubAPIAssign::Organization
  include GithubAPIAssign::PullRequest
end
