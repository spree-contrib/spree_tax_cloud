Spree::TaxCloud 
=======================

Spree::TaxCloud is a US sales tax extension for Spree using the Tax Cloud service.

Based on the work of Chris Mar and Drew Tempelmeyer.

TaxCloud Configuration
-----

Create an account with Tax Cloud...

[https://taxcloud.net](https://taxcloud.net)

...and get an `api_login_id` and `api_key`.

Spree Configuration
------------------------

Add the extension to your Gemfile:

```ruby
gem 'spree_tax_cloud', github: 'spree-contrib/spree_tax_cloud', branch: 'master'
```

And add it to your bundle:

```
bundle install
```

Run below to install migrations:

```
bundle exec rails g spree_tax_cloud:install
```

In the Admin section of Spree, go to Configuration, then select TaxCloud Settings.

Enter your `api_login_id` and `api_key`, and optionally your USPS login.
You can also configure the default Product TIC and Shipping TIC for TaxCloud to use, although it is recommended to leave the defaults as is: `00000` for product default and `11010` for shipping default.

All Products will default to the default product TIC specified here unless they are given an explicit value.
Specific product-level TICs may be specified per-product in the Products section of the Spree admin backend. If you are uncertain about the correct TIC for a product (whether it be clothing, books, etc.), taxability code information may be obtained from [Tax Cloud](https://taxcloud.net/tic/default.aspx).

To complete your Spree::TaxCloud configuration, you will need to create a TaxRate to apply rates obtained from Tax Cloud to your Spree LineItems and Shipments.
Under Configuration select Tax Rates, and click Create a New Tax Rate. Recommended defaults are as follows:

- Name: `Sales Tax` (This label will be visible to users during the checkout process)
- Zone: `USA` (Note that TaxCloud is only designed for United States sales tax)
- Rate: `0.0` (Note that the actual rates will be applied by the calculator)
- Tax Category: `Taxable`
- Included in Price: `False` (US taxes are 'additional' rather than 'included')
- Show Rate in Label: `False` (We will not display the static rate, which is left at `0%`)
- Calculator: `Tax Cloud`

Notes
------------------------

Spree::TaxCloud is designed to function in a single TaxCategory.
It is expected that all Products and all ShippingMethods will be in the same TaxCategory as the one configured for the TaxRate using the Tax Cloud calculator above (in this example, `Taxable`).

Spree::TaxCloud is designed to perform all US-related tax calculation itself, and as such does not use Spree configuration like TaxCategories to specify whether goods are Taxable, Tax-Exempt, Clothing, Food, etc.
Spree::TaxCloud does not use the Spree configuration `tax_address` (which specifies whether the shipping or billing address should be used to compute tax), instead _always_ using the shipping address if possible, and only falling back to the billing address if the shipping address is `nil`.
(Asking Spree::TaxCloud to compute orders whose shipping _and_ billing addresses are `nil` will result in an exception.)

TODO
----

Some work on the Spree:TaxCloud extension is ongoing. Namely:

- [x] Fill out a more complete set of feature specs using the test case scenarios provided by Tax Cloud.

- [ ] Address Validation: Support an address validation step via the Tax Cloud gem (which will fix the one non-passing spec at the moment).

- [ ] Split Shipments: Scope Tax Cloud transactions to Shipments rather than Orders, to account for the unusual cases where sales tax depends on the origin address as well as, or instead of, the destination address.

- [ ] Item Returns: Create feature specs and make the appropriate API calls to properly process sales tax on item returns.

- [ ] Promotions: Spree::TaxCloud is not (yet) fully compatible with some types of Spree promotions. For instance in cases such as "$10 off all orders over $100," it is not explicit how such a discount will affect the costs of individual items. In these cases, Spree::TaxCloud will fall back to charging sales tax on the full (undiscounted) item price.

Discussion and pull requests addressing this functionality are welcomed.

COPYRIGHT
---------

[Copyright]( http://jet.mit-license.org/ ) by Jerrold R Thompson 
