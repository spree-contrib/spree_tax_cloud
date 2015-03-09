require 'spec_helper'

describe 'Checkout', js: true do
  let!(:usa) { create(:country, name: "United States of America", states_required: true) }
  let!(:alabama) { create(:state, name: "Alabama", abbr: "AL", country: usa) }
  let!(:georgia) { create(:state, name: "Georgia", abbr: "GA", country: usa) }
  let!(:minnesota) { create(:state, name: "Minnesota", abbr: "MN", country: usa) }
  let!(:oklahoma) { create(:state, name: "Oklahoma", abbr: "OK", country: usa) }
  let!(:washington) { create(:state, name: "Washington", abbr: "WA", country: usa) }

  let!(:zone) do
    zone = create(:zone, name: "US")
    zone.members.create(zoneable: usa)
    zone
  end

  let!(:uk) { create(:country, name: "United Kingdom", states_required: false, iso_name: "UNITED KINGDOM", iso: "UK", iso3: "GBR", numcode: 826) }
  let!(:uk_address) { create(:address, country: uk, state: nil, zipcode: "SW1A 1AA") }
  let!(:non_us_zone) do
    zone = create(:zone, name: "Rest of the world")
    zone.members.create(zoneable: uk)
    zone
  end

  let!(:shipping_calculator) { create(:calculator) }
  # default calculator in the Spree factory is flat rate of $10, which is exactly what we want
  let!(:shipping_method) { create(:shipping_method, tax_category_id: 1, calculator: shipping_calculator, zones: [zone, non_us_zone]) }
  let!(:stock_location) { create(:stock_location, country_id: stock_location_address.country.id, state_id: stock_location_address.state.id, address1: stock_location_address.address1, city: stock_location_address.city, zipcode: stock_location_address.zipcode) }
  let!(:mug) { create(:product, name: "RoR Mug", price: 10) }
  let!(:shirt) { create(:product, name: "Shirt", price: 10, tax_cloud_tic: 20010) }
  let!(:payment_method) { create(:check_payment_method) }

  let!(:tax_rate) { create(:tax_rate, amount: 0, name: "Sales Tax", zone: zone, calculator: Spree::Calculator::TaxCloudCalculator.create, tax_category: Spree::TaxCategory.first, show_rate_in_label: false) }
  let!(:flat_tax_rate) { create(:tax_rate, amount: 0.1, name: "Flat Sales Tax", zone: non_us_zone, tax_category: Spree::TaxCategory.first, show_rate_in_label: false) }

  before do
    stock_location.stock_items.update_all(count_on_hand: 1)
  end

  it "should display tax lookup error if invalid address" do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"

    fill_in_address(alabama_address)
    fill_in "order_bill_address_attributes_zipcode", with: '12345'

    click_button "Save and Continue"
    click_button "Save and Continue"

    click_button "Save and Continue"
    page.should have_content(/Address Verification Failed/i)
  end

  it "should tolerate a missing sku without throwing a Tax Cloud exception" do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"

    fill_in_address(alabama_address)
    Spree::Product.where(name: "RoR Mug").first.update_attributes(sku: "")

    click_button "Save and Continue"
    page.should_not have_content(/Address Verification Failed/i)
  end

  it "should calculate and display tax on payment step and allow full checkout" do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    fill_in_address(alabama_address)
    click_button "Save and Continue"
    click_button "Save and Continue"

    click_on "Save and Continue"
    expect(current_path).to match(spree.order_path Spree::Order.last)
  end

  it 'should not break when removing all items from cart after a tax calculation has been created' do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    fill_in_address(alabama_address)
    click_button "Save and Continue"
    click_button "Save and Continue"
    page.should_not have_content(/Sales Tax/i)
    page.should have_content(/Order Total: \$20.00/i) # Alabama orders are configured under this API key to have no tax
    visit spree.cart_path
    find('a.delete').click
    page.should have_content(/Shopping Cart/i)
    page.should_not have_content(/Internal Server Error/i)
  end

  it "should only calculate using tax cloud for orders that use the tax cloud calculator" do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    fill_in_address(uk_address)

    click_button "Save and Continue"
    # There should not be a check on the address because
    # the rate is not handled by TaxCloud.
    expect(page).not_to have_content(/Address Verification Failed/i)

    click_button "Save and Continue"
    click_button "Save and Continue"

    expect(current_path).to match(spree.order_path(Spree::Order.last))
    expect(page).not_to have_content(/Address Verification Failed/i)
  end

  it 'completes TaxCloud test case 1a' do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Order Total: \$10/i)
    fill_in_address(test_case_1a_address)
    click_button "Save and Continue"
    # From TaxCloud:
    # This address will not verify correctly (the VerifyAddress API call
    # will return an error). That is okay. Occasionally an address cannot be verified. When
    # that happens, pass the destination address as originally entered to Lookup. The address
    # can still be passed to Lookup. The only error that should prevent an order from processing
    # is when the USPSID used is not valid, or a customer provided zip code does not exist
    # within the customer provided state (discussed later in Test Case 7, Handling Errors).
    page.should have_content(/Sales Tax \$0.94/i)
  end

  it 'completes TaxCloud test case 1b' do
    add_to_cart("RoR Mug")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Item Total: \$10/i)
    fill_in_address(test_case_1b_address)
    click_button "Save and Continue"
    # From TaxCloud:
    # The destination address used as-is will not give the most accurate
    # rate. The verified address will give the correct result.
    page.should have_content(/Sales Tax \$0.95/i)
  end

  it 'completes TaxCloud test case 2a' do
    add_to_cart("Shirt")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Item Total: \$10/i)
    fill_in_address(test_case_2_address)
    click_button "Save and Continue"

    page.should_not have_content(/Address Verification Failed/i)
    click_button "Save and Continue"

    page.should_not have_content(/Sales Tax/i)
    page.should have_content(/Order Total: \$20/i)

    click_on "Save and Continue"

    expect(current_path).to match(spree.order_path Spree::Order.last)
    page.should_not have_content(/Sales Tax/i)
    page.should have_content(/ORDER TOTAL: \$20/i)
  end

  it 'completes TaxCloud test case 2b' do
    add_to_cart("RoR Mug")
    add_to_cart("Shirt")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Item Total: \$20/i)
    fill_in_address(test_case_2_address)
    click_button "Save and Continue"

    page.should have_content(/Sales Tax \$0.76/i)
    page.should have_content(/Order Total: \$30.76/i)
    page.should_not have_content(/Address Verification Failed/i)
    click_button "Save and Continue"

    page.should have_content(/Sales Tax \$1.52/i)
    page.should have_content(/Order Total: \$31.52/i)
    # The argument could be made that two $0.7625 tax charges sum to
    # $1.525, which rounds up to $1.53. However, that's not how Spree does it.
    # Confirmed in 7/14/14 conversation with TaxCloud CEO David Campbell
    # that $1.52 is the correct figure: tax is NOT summed and then rounded,
    # but rather is rounded per-line-item, then summed.

    click_on "Save and Continue"

    expect(current_path).to match(spree.order_path(Spree::Order.last))
    page.should have_content(/Sales Tax \$1.52/i)
    page.should have_content(/ORDER TOTAL: \$31.52/i)
  end

  it 'completes TaxCloud test case 3' do
    add_to_cart("Shirt")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Item Total: \$10/i)
    fill_in_address(test_case_3_address)
    click_button "Save and Continue"

    page.should_not have_content(/Address Verification Failed/i)
    click_button "Save and Continue"

    page.should have_content(/Sales Tax \$0.84/i)
    page.should have_content(/Order Total: \$20.84/i)

    click_on "Save and Continue"

    expect(current_path).to match(spree.order_path(Spree::Order.last))
    page.should have_content(/Sales Tax \$0.84/i)
    page.should have_content(/ORDER TOTAL: \$20.84/i)
  end

  # it 'completes TaxCloud test case 4' do
  # TODO
  # end
  #
  # it 'completes TaxCloud test case 5' do
  # TODO
  # end

  it 'completes TaxCloud test case 6' do
    add_to_cart("Shirt")
    click_button "Checkout"

    fill_in "order_email", with: "test@example.com"
    click_button "Continue"
    page.should have_content(/Item Total: \$10/i)
    fill_in_address(test_case_6_address)
    click_button "Save and Continue"

    page.should have_content(/Sales Tax \$0.80/i)
    page.should have_content(/Order Total: \$20.80/i)
    page.should_not have_content(/Address Verification Failed/i)
    click_button "Save and Continue"

    page.should have_content(/Sales Tax \$1.60/i)
    page.should have_content(/Order Total: \$21.60/i)

    click_on "Save and Continue"

    expect(current_path).to match(spree.order_path(Spree::Order.last))
    page.should have_content(/Sales Tax \$1.60/i)
    page.should have_content(/ORDER TOTAL: \$21.60/i)
  end

  # it 'completes TaxCloud test case 7' do
  # TODO
  # end

  def add_to_cart(item_name)
    visit spree.products_path
    click_link item_name
    click_button "add-to-cart-button"
  end

  def fill_in_address(address)
    fieldname = "order_bill_address_attributes"
    fill_in "#{fieldname}_firstname", with: address.first_name
    fill_in "#{fieldname}_lastname", with: address.last_name
    fill_in "#{fieldname}_address1", with: address.address1
    fill_in "#{fieldname}_city", with: address.city
    select address.country.name, from: "#{fieldname}_country_id"

    # Wait for the ajax to complete for the states selector.
    Timeout.timeout(Capybara.default_wait_time) do
      loop do
        break if page.evaluate_script("jQuery.active").to_i == 0
      end
    end

    if address.state != nil
      select address.state.name, from: "#{fieldname}_state_id"
    else
      expect(page).not_to have_css("##{fieldname}_state_id.required")
    end
    fill_in "#{fieldname}_zipcode", with: address.zipcode
    fill_in "#{fieldname}_phone", with: address.phone
  end

  def stock_location_address
    stock_location_address = Spree::Address.new(
    firstname: "Testing",
    lastname: "Location",
    address1: "3121 W Government Way",
    city: "Seattle",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "WA").first,
    zipcode: "98199-1402",
    phone: "(555) 5555-555")
  end

  def test_case_1a_address
    stock_location_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "1 3rd Street",
    city: "Seattle",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "WA").first,
    zipcode: "98001",
    phone: "(555) 5555-555")
  end

  def test_case_1b_address
    stock_location_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "354 Union Ave NE",
    city: "Renton",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "WA").first,
    zipcode: "98059",
    phone: "(555) 5555-555")
  end

  def test_case_2_address
    stock_location_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "75 Rev Martin Luther King Jr Drive",
    city: "St. Paul",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "MN").first,
    zipcode: "55155",
    phone: "(555) 5555-555")
  end

  def test_case_3_address
    stock_location_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "2300 N Lincoln Blvd",
    city: "Oklahoma City",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "OK").first,
    zipcode: "73105",
    phone: "(555) 5555-555")
  end

  def test_case_6_address
    stock_location_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "384 Northyards Blvd NW",
    city: "Atlanta",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(abbr: "GA").first,
    zipcode: "30313",
    phone: "(555) 5555-555")
  end

  def alabama_address
    alabama_address = Spree::Address.new(
    firstname: "John",
    lastname: "Doe",
    address1: "143 Swan Street",
    city: "Montgomery",
    country: Spree::Country.where(name: "United States of America").first,
    state: Spree::State.where(name: "Alabama").first,
    zipcode: "36110",
    phone: "(555) 5555-555")
  end
end
