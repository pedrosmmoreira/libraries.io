class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    project_scope = Project.includes(:github_repository).maintained.with_description
    repo_scope = GithubRepository.source.with_description.open_source.limit(6)

    @trending_projects = project_scope.recently_created.hacker_news.limit(10).to_a.uniq(&:name).first(6)
    @trending_repos = repo_scope.trending.hacker_news
    @new_projects = project_scope.order('projects.created_at desc').limit(6)
    @new_repos = repo_scope.order('created_at desc')
  end

  private

  helper_method :repo_search
  def repo_search(sort)
    search = search(GithubRepository, sort)
    ids = search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    search.records.sort_by { |u| indexes[u.id] }
  end

  helper_method :project_search
  def project_search(sort)
    search = search(Project, sort)
    ids = search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    search.records.sort_by { |u| indexes[u.id] }
  end

  def search(klass, sort)
    klass.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
  end
end
