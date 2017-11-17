require 'pghub/auto_assign/version'
require 'pghub/base'

include GithubAPI::Connection

class UnknownTeamError < StandardError; end
class TooManyNumOfMembersError < StandardError; end

module Pghub
  module AutoAssign
    class << self
      def post(issue_path, opened_pr_user)
        assignees = select_assignees(opened_pr_user)
        reviewers = select_reviewers(opened_pr_user)
        assign(issue_path, assignees)
        request_review(issue_path, reviewers)
      end

      private

      def all_members
        teams_data.each_with_object({}) do |team, members|
          members[team[:name].to_sym] = team_members(team[:id])
        end
      end

      def teams_data
        response = connection.get("/orgs/#{Pghub.config.github_organization}/teams?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body).map(&:with_indifferent_access)

        team_names = body.map { |data| data[:name] }
        validate_teams(team_names)

        body.map { |data| { id: data[:id], name: data[:name] } }
      end

      def validate_teams(valid_teams)
        Pghub.config.num_of_assignees_per_team.each_key do |team|
          raise UnknownTeamError, "Unknown #{team}" unless valid_teams.include?(team.to_s)
        end
        Pghub.config.num_of_reviewers_per_team.each_key do |team|
          raise UnknownTeamError, "Unknown #{team}" unless valid_teams.include?(team.to_s)
        end
      end

      def team_members(team_id)
        response = connection.get("/teams/#{team_id}/members?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body).map(&:with_indifferent_access)

        body.map { |h| h[:login] }
      end

      def select_assignees(opened_pr_user)
        assignees = [opened_pr_user]
        return assignees if Pghub.config.num_of_assignees_per_team.empty?

        select_members(assignees, Pghub.config.num_of_assignees_per_team, opened_pr_user)
      end

      def select_reviewers(opened_pr_user)
        reviewers = []
        return reviewers if Pghub.config.num_of_reviewers_per_team.empty?

        select_members(reviewers, Pghub.config.num_of_reviewers_per_team, opened_pr_user)
      end

      def select_members(members, num_of_members_per_team, opened_pr_user)
        num_of_members_per_team.each do |team, number|
          team_members = all_members[team.to_sym]
          raise TooManyNumOfMembersError, "too many number of members per team #{team}" if number > team_members.length

          if team_members.include?(opened_pr_user)
            team_members.delete(opened_pr_user)
            number -= 1
          end

          members += team_members.sample(number)
        end

        members
      end

      def assign(issue_path, assignees)
        connection.post do |req|
          req.url "/repos/#{Pghub.config.github_organization}/#{issue_path}/assignees?access_token=#{Pghub.config.github_access_token}"
          req.headers['Content-Type'] = 'application/json'
          req.body = { assignees: assignees }.to_json
        end
      end

      def request_review(issue_path, reviewers)
        pr_path = issue_path.gsub('issues', 'pulls')

        connection.post do |req|
          req.url "/repos/#{Pghub.config.github_organization}/#{pr_path}/requested_reviewers?access_token=#{Pghub.config.github_access_token}"
          req.headers['Content-Type'] = 'application/json'
          req.body = { reviewers: reviewers }.to_json
        end
      end
    end
  end
end
