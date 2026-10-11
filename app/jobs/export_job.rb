# A native Sidekiq job, so its job ID can be shown with the export. Sidekiq
# stores arguments as JSON, so the options arrive with string keys.
class ExportJob
  include Sidekiq::Job

  def perform(export_id, options)
    format = options.fetch("format")
    raise ArgumentError, "Unsupported export format: #{format}" unless format == "markdown"

    Export.find(export_id).generate
  end
end
