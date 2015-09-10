module Recommendable
  extend ActiveSupport::Concern

  def recommended_projects
    projects = Project.where(id: recommended_project_ids).order("position(','||id::text||',' in '#{recommended_project_ids.join(',')}'), rank DESC")
    projects = unfiltered_recommendations if projects.empty?
    projects
  end

  def recommended_project_ids
    ids = favourite_recommendation_ids + most_depended_on_recommendation_ids + most_watched_recommendation_ids
    ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|k,v| -v}.map(&:first)
  end

  def already_watching_ids
    subscribed_projects.pluck(:id)
  end

  def recommendation_filter(scope)
    filtered = scope.where.not(id: already_watching_ids)
    filtered = filtered.where('lower(projects.language) IN (?)', favourite_languages.map(&:downcase)) if favourite_languages.any?
    filtered.pluck(:id)
  end

  def favourite_recommendation_ids
    return [] if github_user.nil?
    recommendation_filter github_user.favourite_projects.limit(100)
  end

  def most_depended_on_recommendation_ids
    recommendation_filter Project.most_dependents.limit(100)
  end

  def most_watched_recommendation_ids
    recommendation_filter Project.most_watched.limit(100)
  end

  def unfiltered_recommendations
    ids = Project.most_dependents.limit(100).pluck(:id) + Project.most_watched.limit(100).pluck(:id)
    ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|k,v| -v}.map(&:first)
    Project.where(id: ids).order('rank DESC')
  end

  def favourite_languages(limit = 3)
    @favourite_languages ||= begin
      # your github Repositories
      languages = github_repositories.pluck(:language).compact

      # repositoreis you've contributed to
      languages += github_user.contributed_repositories.pluck(:language).compact if github_user.present?

      # Repositories your subscribed to (twice to bump those languages)
      languages += subscribed_projects.pluck(:language).compact + subscribed_projects.pluck(:language).compact

      languages = languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|k,v| -v}.first(3).map(&:first)
      languages ||= []
    end
  end
end