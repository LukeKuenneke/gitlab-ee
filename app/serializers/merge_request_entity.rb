class MergeRequestEntity < IssuableEntity
<<<<<<< HEAD
  expose :approvals_before_merge
=======
>>>>>>> ce/8-14-stable
  expose :in_progress_merge_commit_sha
  expose :locked_at
  expose :merge_commit_sha
  expose :merge_error
  expose :merge_params
  expose :merge_status
  expose :merge_user_id
  expose :merge_when_build_succeeds
<<<<<<< HEAD
  expose :rebase_commit_sha
  expose :rebase_in_progress?, if: { type: :full }
=======
>>>>>>> ce/8-14-stable
  expose :source_branch
  expose :source_project_id
  expose :target_branch
  expose :target_project_id
end
