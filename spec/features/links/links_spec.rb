require 'rails_helper'

feature 'The links for a local authority' do
  before do
    User.create(email: 'user@example.com', name: 'Test User', permissions: ['signin'])
    @local_authority = FactoryGirl.create(:local_authority, name: 'Angus', tier: 'county')
    @service = FactoryGirl.create(:service, label: 'Service', lgsl_code: 1, tier: 'county/unitary')
    @interaction_1 = FactoryGirl.create(:interaction, label: 'Interaction 1', lgil_code: 3)
    @interaction_2 = FactoryGirl.create(:interaction, label: 'Interaction 2', lgil_code: 4)
    @service_interaction_1 = FactoryGirl.create(:service_interaction, service: @service, interaction: @interaction_1)
    @service_interaction_2 = FactoryGirl.create(:service_interaction, service: @service, interaction: @interaction_2)
  end

  describe "when no links exist for the service interaction" do
    before do
      visit local_authority_service_interactions_path(local_authority_slug: @local_authority.slug, service_slug: @service.slug)
    end

    it "shows an empty cell for the link next to the interactions" do
      expect(page).to have_table_row('3', 'Interaction 1 No link', '', 'Add link')
      expect(page).to have_table_row('4', 'Interaction 2 No link', '', 'Add link')
    end

    it "shows an empty cell when editing a blank link" do
      within('.table') { click_on('Add link', match: :first) }
      expect(page.find_by_id('link_url').value).to be_blank
    end

    it "allows us to save a new link and view it" do
      within('.table') { click_on('Add link', match: :first) }
      fill_in('link_url', with: 'http://angus.example.com/new-link')
      click_on('Save')

      expect(page).to have_table_row('3', 'Interaction 1 http://angus.example.com/new-link', '', 'Edit link')
      expect(page).to have_content('Link has been saved.')
    end

    it "shows the name of the local authority" do
      within('.table') { click_on('Add link', match: :first) }
      expect(page).to have_css('h1', text: @local_authority.name)
      expect(page).to have_link(@local_authority.homepage_url)
    end

    it "does not save invalid links" do
      link_count = Link.count
      within('.table') { click_on('Add link', match: :first) }
      click_on('Save')

      expect(Link.count).to eq(link_count)
      expect(page).to have_content('Please enter a valid link')
    end

    it "does not show a delete button after clicking on add" do
      within('.table') { click_on('Add link', match: :first) }
      expect(page).not_to have_button("Delete")
    end
  end

  describe "when links exist for the service interaction" do
    before do
      FactoryGirl.create(:link, url: 'http://angus.example.com/service-interaction-1', local_authority: @local_authority, service_interaction: @service_interaction_1)
      FactoryGirl.create(:link, url: 'https://angus.example.com/service-interaction-2', local_authority: @local_authority, service_interaction: @service_interaction_2)
      visit local_authority_service_interactions_path(local_authority_slug: @local_authority.slug, service_slug: @service.slug)
    end

    it "shows the url for the link next to the relevant interaction" do
      expect(page).to have_table_row('3', 'Interaction 1 http://angus.example.com/service-interaction-1', '', 'Edit link')
      expect(page).to have_table_row('4', 'Interaction 2 https://angus.example.com/service-interaction-2', '', 'Edit link')
    end

    it "shows the urls as clickable links" do
      expect(page).to have_link('http://angus.example.com/service-interaction-1', href: 'http://angus.example.com/service-interaction-1')
      expect(page).to have_link('https://angus.example.com/service-interaction-2', href: 'https://angus.example.com/service-interaction-2')
    end

    it "allows us to edit a link" do
      expect(page).to have_link('Edit link',
        href: edit_local_authority_service_interaction_links_path(
          local_authority_slug: @local_authority.slug,
          service_slug: @service.slug,
          interaction_slug: @interaction_1.slug
        )
      )
      within('.table') { click_on('Edit link', match: :first) }
      expect(page).to have_field('link_url', with: 'http://angus.example.com/service-interaction-1')
      expect(page).to have_button('Save')
    end

    it "allows us to save an edited link and view it" do
      within('.table') { click_on('Edit link', match: :first) }
      fill_in('link_url', with: 'http://angus.example.com/changed-link')
      click_on('Save')

      expect(page).to have_table_row('3', 'Interaction 1 http://angus.example.com/changed-link', '', 'Edit link')
      expect(page).to have_table_row('4', 'Interaction 2 https://angus.example.com/service-interaction-2', '', 'Edit link')
      expect(page).to have_content('Link has been saved.')
    end

    it "does not save an edited link when 'Cancel' is clicked" do
      within('.table') { click_on('Edit link', match: :first) }
      fill_in('link_url', with: 'http://angus.example.com/changed-link')
      click_on('Cancel')

      expect(page).to have_link('http://angus.example.com/service-interaction-1', href: 'http://angus.example.com/service-interaction-1')
    end

    it "shows a warning if the URL is not a valid URL" do
      within('.table') { click_on('Edit link', match: :first) }
      fill_in('link_url', with: 'linky loo')
      click_on('Save')

      expect(page).to have_content('Please enter a valid link')
      expect(page).to have_field('link_url', with: 'linky loo')
      expect(page).to have_css('.has-error')
    end

    it "allows us to delete a link" do
      within('.table') { click_on('Edit link', match: :first) }
      fill_in('link_url', with: 'http://angus.example.com/link-to-delete')
      click_on('Save')

      expect(page).to have_table_row('3', 'Interaction 1 http://angus.example.com/link-to-delete', '', 'Edit link')

      within('.table') { click_on('Edit link', match: :first) }
      click_on('Delete')

      expect(page).to have_table_row('3', 'Interaction 1 No link', '', 'Add link')
    end
  end
end