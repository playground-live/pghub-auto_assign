require 'pghub/assign/version'
require 'pghub/base'

include GithubAPI::Connection

class UnknownTeamError < StandardError; end

module Pghub
  module Assign
    class << self
      def post(issue_path, opened_user)
        all_members = {}

        all_teams_data.each do |team|
          all_members[team['name'].to_s] = all_members_from(team['id'])
        end

        selected_assignees = assignees(all_members, opened_user)
        assign(issue_path, selected_assignees)

        selected_reviewers = reviewers(selected_assignees, opened_user)
        review_request(issue_path, selected_reviewers)
      end

      private

      def all_teams_data
        response = connection.get("/orgs/#{Pghub.config.github_organization}/teams?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body)

        team_names = body.map { |data| data['name'] }
        team_exists?(Pghub.config.assign_numbers.keys, team_names)

        body.map { |data| { 'id' => data['id'], 'name' => data['name'] } }
      end

      def team_exists?(configured_teams, valid_teams)
        configured_teams.each do |team|
          raise UnknownTeamError, "Unknown #{team}" unless valid_teams.include?(team)
        end
      end

      # get members related to teams from github
      # return { "team_name": ["member_name", "member_name"...] }
      def all_members_from(team_id)
        response = connection.get("/teams/#{team_id}/members?access_token=#{Pghub.config.github_access_token}")
        body = JSON.parse(response.body)

        body.map { |h| h['login'] }
      end

      # selected assignees
      # return ["member_name", "member_name"]
      def assignees(all_members, opened_user)
        target_team_numbers = Pghub.config.assign_numbers
        assignees = [opened_user]

        target_team_numbers.each do |team, num_of_members|
          members = all_members[team.to_s]

          raise 'too many assign_numbers' if num_of_members > members.length

          if all_members[team.to_s].include?(opened_user)
            members.delete(opened_user)
            num_of_members -= 1
          end

          num_of_members.times do
            selected_member = members.sample
            members.delete(selected_member)
            assignees << selected_member unless assignees.include?(selected_member)
          end
        end

        assignees
      end

      # selected reviewers (except a member who opened PR)
      def reviewers(assignees, opened_user)
        assignees.delete(opened_user)
        assignees
      end

      # post assign data
      def assign(issue_path, assignees)
        connection.post do |req|
          req.url "/repos/#{Pghub.config.github_organization}/#{issue_path}/assignees?access_token=#{Pghub.config.github_access_token}"
          req.headers['Content-Type'] = 'application/json'
          req.body = { assignees: assignees }.to_json
        end
      end

      # post review request data
      def review_request(issue_path, reviewers)
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
