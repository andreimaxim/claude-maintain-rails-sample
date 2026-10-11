class DigestMailer < ApplicationMailer
  # Lists the reader's ready notes last updated on the day of the request.
  # Active Job deserializes the request time in the worker's time zone (UTC),
  # so that is the day the digest covers, which can differ from the reader's
  # local day near midnight.
  def daily_digest
    @reader, requested_at = params.values_at(:reader, :requested_at)
    @date = requested_at.to_date
    @notes = @reader.notes.status_ready.where(updated_at: requested_at.all_day).includes(:notebook).order(:updated_at, :id)
    @completion = BigDecimal(params[:completion])

    mail to: @reader.email, subject: "Your reading digest for #{l @date, format: :long}"
  end
end
