class ElasticIndexerWorker
  include Sidekiq::Worker
  include Elasticsearch::Model::Client::ClassMethods

  sidekiq_options queue: :elasticsearch

  ISSUE_TRACKED_FIELDS = %w(assignee_id author_id confidential)

  def perform(operation, class_name, record_id, options = {})
    klass = class_name.constantize

    case operation.to_s
    when /index|update/
      record = klass.find(record_id)
      record.__elasticsearch__.client = client

      if [Project, PersonalSnippet, ProjectSnippet, Snippet].include?(klass)
        record.__elasticsearch__.__send__ "#{operation}_document"
      else
        record.__elasticsearch__.__send__ "#{operation}_document", parent: record.es_parent
      end

      update_issue_notes(record, options["changed_fields"]) if klass == Issue
    when /delete/
      client.delete index: klass.index_name, type: klass.document_type, id: record_id

      clear_project_indexes(record_id) if klass == Project
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveRecord::RecordNotFound
    # These types of the errors can be raised when
    # record is updated then immidiately removed before updating is handled.
    # One more case - if you have enabled indexing but not every item is already indexed, in this case
    # you will also get the error on updating or removing those records. There is a planty of other cases
    true
  end

  def update_issue_notes(record, changed_fields)
    if changed_fields && (changed_fields & ISSUE_TRACKED_FIELDS).any?
      Note.import_with_parent query: -> { where(noteable: record) }
    end
  end

  def clear_project_indexes(record_id)
    # Remove repository index
    client.delete_by_query({
      index: Repository.__elasticsearch__.index_name,
      body: {
        query: {
          or: [
            { term: { "commit.rid" => record_id } },
            { term: { "blob.rid" => record_id } }
          ]
        }
      }
    })

    # Remove wiki index
    client.delete_by_query({
      index: ProjectWiki.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "blob.rid" => "wiki_#{record_id}" }
        }
      }
    })
  end
end
