require 'rails_helper'
require 'local-links-manager/check_links/link_status_requester'
require "gds_api/test_helpers/link_checker_api"

describe LocalLinksManager::CheckLinks::LinkStatusRequester do
  include GdsApi::TestHelpers::LinkCheckerApi

  subject(:link_status_requester) { described_class.new }

  context "links for enabled services" do
    let(:local_authority_1) { FactoryGirl.create(:local_authority) }
    let(:local_authority_2) { FactoryGirl.create(:local_authority) }
    let!(:link_1) { FactoryGirl.create(:link, local_authority: local_authority_1, url: 'http://www.example.com') }
    let!(:link_2) { FactoryGirl.create(:link, local_authority: local_authority_2, url: 'http://www.example.com/example.html') }

    it "makes a batch request to the link checker API" do
      stub_1 = link_checker_api_create_batch(
        uris: [link_1.url, local_authority_1.homepage_url],
        webhook_uri: "http://local-links-manager.dev.gov.uk/link-check-callback"
      )

      stub_2 = link_checker_api_create_batch(
        uris: [link_2.url, local_authority_2.homepage_url],
        webhook_uri: "http://local-links-manager.dev.gov.uk/link-check-callback"
      )

      stub_request(:get, "/mapit/")

      link_status_requester.call

      expect(stub_1).to have_been_requested
      expect(stub_2).to have_been_requested
    end
  end

  context "with links for disabled Services" do
    let!(:disabled_service_link) { FactoryGirl.create(:link_for_disabled_service) }

    it "does not test links other than the local authority homepage" do
      homepage_stub = link_checker_api_create_batch(
        uris: [disabled_service_link.local_authority.homepage_url],
        webhook_uri: "http://local-links-manager.dev.gov.uk/link-check-callback"
      )

      homepage_and_link_stub = link_checker_api_create_batch(
        uris: [disabled_service_link.url, disabled_service_link.local_authority.homepage_url],
        webhook_uri: "http://local-links-manager.dev.gov.uk/link-check-callback"
      )

      link_status_requester.call

      expect(homepage_stub).to have_been_requested
      expect(homepage_and_link_stub).not_to have_been_requested
    end
  end
end
