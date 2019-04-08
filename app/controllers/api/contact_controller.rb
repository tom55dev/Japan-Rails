class Api::ContactController < ApiController
  def create_ticket
    @form = ::ContactForm.new(
      contact_form_params
    )
    if @form.save
      render json: { success: true, message: "We've received your message. Messages are sorted by the time of the most recent message so please avoid submitting multiple requests for a faster response. One of our representatives will be in touch with you soon." }
    else
      render json: {
        success: false,
        error: {
          message: 'Sorry, your request could not be submitted. Please fix the errors below and try again.',
          details: @form.errors.full_messages
        }
      }, status: 400
    end
  end

  private

  def contact_form_params
    params.require(:contact_form).
        permit(ContactForm::ATTRIBUTES)
  end
end
