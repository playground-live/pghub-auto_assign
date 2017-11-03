require 'pghub/assign/version'
require 'pghub/base'
require 'pghub/github_api_assign'

include GithubAPIAssign

module Pghub
  module Assign
    class << self
      def assign(issue_path)
        assign_client = GithubAPIAssign.new(issue_path)
        assign_client.assign
      end
    end
  end
end
