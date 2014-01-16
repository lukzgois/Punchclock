class PunchesFilterForm
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :since, :until, :project_id, :user_id

  def initialize(params)
    params ||= {}
    @since = params[:since]
    @until = params[:until]
    @project_id = params[:project_id]
    @user_id = params[:user_id]
  end

  def apply_filters(relation)
    if @since.present?
      since_date = Date.strptime(@since, "%d/%m/%Y")
      relation = relation.since(since_date)
    end

    if @until.present?
      until_date = Date.strptime(@until, "%d/%m/%Y")
      relation = relation.until(until_date)
    end

    if @project_id.present?
      relation = relation.where(project_id: @project_id)
    end

    if @user_id.present?
      relation = relation.where(user_id: @user_id)
    end
    relation
  end
end