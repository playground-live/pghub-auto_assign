require 'pghub/assign/version'
require 'pghub/base'

include GithubAPI::Connection

class UnknownTeamError < StandardError; end

module Pghub
  module Assign
    class << self
      def post(issue_path, opened_user)
        all_members = {}

        teams_data.each do |team|
          all_members[team[:name]] = team_members(team[:id])
        end

        assignees = select_assignees(all_members, opened_user)
        reviewers = select_reviewers(assignees, opened_user)
        assign(issue_path, assignees)
        review_request(issue_path, reviewers)
      end

      private

      def teams_data
        response = connection.get("/orgs/#{Pghub.config.github_organization}/teams?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body)

        team_names = body.map { |data| data['name'] }
        validate_teams(Pghub.config.num_of_assignees.keys, team_names)

        body.map { |data| { id: data['id'], name: data['name'] } }
      end

      def validate_teams(configured_teams, valid_teams)
        configured_teams.each do |team|
          raise UnknownTeamError, "Unknown #{team}" unless valid_teams.include?(team)
        end
      end

      def team_members(team_id)
        response = connection.get("/teams/#{team_id}/members?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body)

        body.map { |h| h['login'] }
      end

      def select_assignees(all_members, opened_user)
        assignees = [opened_user]

        Pghub.config.num_of_assignees.each do |team, num_of_members|
          team_members = all_members[team.to_s].delete(opened_user)
          raise 'too many assign_numbers' if num_of_members > team_members.length

          num_of_members -= 1 if all_members[team.to_s].include?(opened_user)
          num_of_members.times do
            selected_member = team_members.sample
            assignees << selected_member
            team_members.delete(selected_member)
          end
        end

        assignees
      end

      def select_reviewers(assignees, opened_user)
        assignees.delete(opened_user)
        assignees
      end

      def assign(issue_path, assignees)
        request("#{issue_path}/assignees", { assignees: assignees }.to_json)
      end

      def review_request(issue_path, reviewers)
        pr_path = issue_path.gsub('issues', 'pulls')
        request("#{pr_path}/requested_reviewers", { reviewers: reviewers }.to_json)
      end

      def request(request_path, body)
        connection.post do |req|
          req.url "/repos/#{Pghub.config.github_organization}/#{request_path}?access_token=#{Pghub.config.github_access_token}"
          req.headers['Content-Type'] = 'application/json'
          req.body = body
        end
      end
    end
  end
end
