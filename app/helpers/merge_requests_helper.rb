module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_path_for_fork_from_push_event(event)
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, event.project.forked_from_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    {
      merge_request: {
        source_project_id: event.project.id,
        target_project_id: target_project.id,
        source_branch: event.branch_name,
        target_branch: target_project.repository.root_ref
      }
    }
  end

  def mr_css_classes(mr)
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path(merge_request)
    build_url = merge_request.source_project.ci_service.build_page(merge_request.last_commit.sha, merge_request.source_branch)
    parsed_url = URI.parse(build_url)

    unless parsed_url.userinfo.blank?
      parsed_url.userinfo = ''
    end

    parsed_url.to_s
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.path_with_namespace}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  def issues_sentence(issues)
    issues.map { |i| "##{i.iid}" }.to_sentence
  end

  def mr_change_branches_path(merge_request)
    new_namespace_project_merge_request_path(
      @project.namespace, @project,
      merge_request: {
        source_project_id: @merge_request.source_project_id,
        target_project_id: @merge_request.target_project_id,
        source_branch: @merge_request.source_branch,
        target_branch: nil
      }
    )
  end

  def render_items_list(items, separator = "and")
    items_cnt = items.size

    case items_cnt
    when 1
      items.first
    when 2
      "#{items.first} #{separator} #{items.last}"
    else
      last_item = items.pop
      "#{items.join(", ")} #{separator} #{last_item}"
    end
  end

  def render_require_section(merge_request)
    str = if merge_request.approvals_left == 1
            "Requires one more approval"
          else
            "Requires #{merge_request.approvals_left} more approvals"
          end

    if merge_request.approvers_left.any?
      more_approvals = merge_request.approvals_left - merge_request.approvers_left.count
      approvers_names = merge_request.approvers_left.map(&:name)

      case true
      when more_approvals > 0
        str << " (from #{render_items_list(approvers_names + ["#{more_approvals} more"])})"
      when more_approvals < 0
        str << " (from #{render_items_list(approvers_names, "or")})"
      else
        str << " (from #{render_items_list(approvers_names)})"
      end
    end

    str
  end
end
