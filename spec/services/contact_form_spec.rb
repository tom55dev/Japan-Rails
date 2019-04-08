require 'rails_helper'

describe ContactForm do
  class TestForm < ContactForm
    def zendesk_category_id
      'support'
    end

    def zendesk_custom_fields
      {}
    end

    def zendesk_body_fields
      {}
    end

    def zendesk_additional_tags
      []
    end
  end

  let!(:form) do
    TestForm.new(
      email: 'test@example.com',
      first_name: 'Test',
      last_name: 'Customer',
      subject: 'Hello',
      message: 'Something',
      purpose: 'Product'
    )
  end

  before do
    allow(Rails.application.secrets).to receive(:zendesk_custom_field_ids).and_return(
      brand: 1,
      category: 2,
      purpose: 3
    )
  end

  describe 'validations' do
    it 'checks email is an email address' do
      form.email = nil
      expect(form).to be_invalid
      expect(form.errors[:email]).to be_present

      form.email = 'test'
      expect(form).to be_invalid
      expect(form.errors[:email]).to be_present

      form.email = 'test@example.com'
      expect(form).to be_valid
    end

    [:first_name, :last_name, :subject, :message].each do |field|
      it "checks #{field} is present" do
        form.send("#{field}=", nil)
        expect(form).to be_invalid
        expect(form.errors[field]).to be_present

        form.send("#{field}=", 'Not blank')
        expect(form).to be_valid
      end
    end

    it 'checks there are not too many attachments' do
      form.attachments = [double(:attachment)] * (ContactForm::MAX_ATTACHMENTS + 1)

      expect(form).to be_invalid
      expect(form.errors[:base]).to include /attachments/
    end

    it 'checks the attachments are not too big' do
      form.attachments = [
        double(:attachment, size: ContactForm::MAX_TOTAL_ATTACHED_MB * 1000000),
        double(:attachment, size: 1)
      ]

      expect(form).to be_invalid
      expect(form.errors[:base]).to include /attachments/
    end
  end

  describe '#zendesk_body_fields' do
    let!(:form) {
      ContactForm.new(
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'Customer',
        subject: 'Hello',
        message: 'Something',
        purpose: 'Product'
      )
    }
    context 'when there are no additional fields' do
      it 'is blank' do
        expect(form.zendesk_body_fields).to eq({})
      end
    end

    context 'when there are additional fields' do
      before do
        form.purpose = 'Shipping'
        form.account_email = 'test@example.com'
        form.problem = ContactForm::SHIPPING_PROBLEMS.keys.first
      end

      it 'contains the fields' do
        expect(form.zendesk_body_fields['Account Email']).to eq form.account_email
        expect(form.zendesk_body_fields['Problem']).to eq form.problem
      end
    end
  end

  describe '#zendesk_additional_tags' do
    let!(:form) {
      ContactForm.new(
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'Customer',
        subject: 'Hello',
        message: 'Something',
        purpose: 'Product'
      )
    }

    context 'when there are no additional tags' do
      before { form.purpose = 'Reward Haul' }

      it 'is empty' do
        expect(form.zendesk_additional_tags).to be_empty
      end
    end

    context 'when there are additional tags from the purpose' do
      before { form.purpose = 'Shipping' }

      it 'finds the tags' do
        expect(form.zendesk_additional_tags).to contain_exactly('shipment')
      end
    end

    context 'when there are additional tags from the problem type' do
      before do
        form.purpose = 'Shipping'
        form.problem = 'Missing item'
      end

      it 'finds the tags' do
        expect(form.zendesk_additional_tags).to contain_exactly('damaged', 'shipment')
      end
    end
  end

  describe '#save' do
    let!(:successful_response) { double(:response, code: 201, body: { request: { id: 123 } }.to_json) }

    it 'returns false and does nothing when the form is invalid' do
      form.email = nil

      expect(RestClient).not_to receive(:post)
      expect(form.save).to eq false
    end

    it 'returns true after posting JSON to Zendesk' do
      expect(RestClient).to receive(:post).with(
        /requests.json/,
        /\A\{"request":\{.+\}\}\z/,
        content_type: :json,
        accept: :json
      ).and_return(successful_response)

      expect(form.save).to eq true
    end

    it 'sets the requester' do
      expect(RestClient).to receive(:post).with(
        /requests.json/,
        /"requester":\{"name":"Test Customer","email":"test@example.com"\}/,
        content_type: :json,
        accept: :json
      ).and_return(successful_response)

      form.save
    end

    it 'includes the brand and category in the subject line' do
      expect(RestClient).to receive(:post).with(
        /requests.json/,
        /"subject":"\[[A-Z]+\]\[Support\] Hello"/,
        content_type: :json,
        accept: :json
      ).and_return(successful_response)

      form.save
    end

    it 'includes custom purpose field based on secrets IDs' do
      expect(RestClient).to receive(:post).with(
        /requests.json/,
        /"custom_fields".+\{"id":3,"value":"product"\}/,
        content_type: :json,
        accept: :json
      ).and_return(successful_response)

      form.save
    end

    context 'when the request to zendesk fails' do
      it 'adds an error to the form and returns false' do
        expect(RestClient).to receive(:post).and_raise(RestClient::ExceptionWithResponse)

        expect(form.save).to eq false
        expect(form.errors[:base]).to be_present
      end
    end

    context 'when there are attachments' do
      before do
        form.attachments = [
          instance_double(
            ActionDispatch::Http::UploadedFile,
            original_filename: 'test.pdf',
            tempfile: 'testcontent',
            content_type: 'application/pdf',
            size: 10000
          )
        ]
      end

      it 'uploads the attachments' do
        expect(RestClient).to receive(:post).with(/requests.json/, any_args).and_return(successful_response)

        expect(RestClient).to receive(:post).with(
          /uploads.json\?filename=test.pdf/,
          'testcontent',
          content_type: 'application/pdf',
          accept: :json,
          'Authorization' => an_instance_of(String)
        ).and_return(double(:response, code: 201, body: { upload: { token: 'abc123' } }.to_json))

        expect(RestClient).to receive(:put).with(
          /tickets\/123.json/,
          /"comment":\{"body":"User uploaded attachments","uploads":\["abc123"\],"public":false\}/,
          content_type: :json,
          accept: :json,
          'Authorization' => an_instance_of(String)
        ).and_return(successful_response)

        expect(form.save).to eq true
      end
    end
  end
end
