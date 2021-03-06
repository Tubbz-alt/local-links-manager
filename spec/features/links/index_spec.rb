feature "The broken links page" do
  before do
    User.create!(email: "user@example.com", name: "Test User", permissions: %w[signin])

    @service = create(:service, :all_tiers)
    @service_interaction = create(:service_interaction, service: @service)
    @council_a = create(:unitary_council, name: "aaa")
    @council_b = create(:county_council, name: "bbb")
    @council_c = create(:district_council, name: "ccc")
    @council_d = create(:district_council, name: "ddd")
    @link1 = create(:link, local_authority: @council_a, service_interaction: @service_interaction, status: "ok", link_last_checked: "1 day ago", analytics: 911)
    @link2 = create(:link, local_authority: @council_b, service_interaction: @service_interaction, status: "broken", analytics: 37, problem_summary: "A problem")
    @link3 = create(:link, local_authority: @council_c, service_interaction: @service_interaction, status: "broken", analytics: 823, problem_summary: "A problem")
    @link4 = create(:missing_link, local_authority: @council_d, service_interaction: @service_interaction)
    visit "/"
  end

  it "has a breadcrumb trail" do
    expect(page).to have_selector(".breadcrumb")
  end

  it "displays the title of the local transaction for each broken link" do
    expect(page).to have_content("A title")
  end

  it "displays the LGSL code for each broken link" do
    expect(page).to have_content(@service.lgsl_code)
  end

  it "shows the council name for each broken link" do
    expect(page).to have_content(@council_b.name)
    expect(page).to have_content(@council_c.name)
    expect(page).to have_content(@council_d.name)
  end

  it "shows non-200 status links" do
    expect(page).to have_link @link2.url
  end

  it "doesn't show 200 status links" do
    expect(page).not_to have_link @link1.url
  end

  it "shows missing links" do
    expect(page).to have_link "No URL", href: @link4.local_authority.homepage_url
  end

  it "shows missing status" do
    expect(page).to have_content "Missing"
  end

  it "lists the links prioritised by analytics count" do
    expect(@council_c.name).to appear_before(@council_b.name)
  end

  it "shows a count of the number of broken links" do
    within("thead") do
      expect(page).to have_content "3 broken links"
    end
  end

  it "displays a filter box" do
    expect(page).to have_selector(".filter-control-full-width")
  end

  it "has navigation tabs" do
    expect(page).to have_selector(".nav-tabs")
    within(".nav-tabs") do
      expect(page).to have_link "Broken links"
      expect(page).to have_link "Councils"
      expect(page).to have_link "Services"
    end
  end
end
