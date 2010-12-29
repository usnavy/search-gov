Feature: Program
  In order to provide information about hosted search services,
  I want to see information about affiliate program, API / web services and searchUSA.gov
  Scenario:
 Show links to affiliate program, API / web services and searchUSA.gov
    Given I am on the program welcome page
    Then I should see "Affiliate Program" within ".main"
    And I should see "APIs and other web services" within ".main"
    And I should see "Search.USA.gov" within ".main"
    And the "login" link should use full url
    When I follow "program_logo"
    Then I should be on the program welcome page

    When I follow "Login"
    Then I should be on the login page

  Scenario: Visiting the affiliate welcome page as affiliate
    Given I am logged in with email "affiliate_manager@fixtures.org" and password "admin"
    When I go to the program welcome page
    Then the "logout" link should use full url

    When I follow "Logout"
    Then I should be on the login page

  Scenario: Affiliate Program link should be on the affiliates page
    Given I am on the program welcome page
    When I follow "Affiliate Program" within ".main"
    Then I should be on the affiliates page
    And I should see "USASearch Affiliate Program"

  Scenario: APIs and other web services link should be on the affiliates page
    Given I am on the program welcome page
    When I follow "APIs and other web services" within ".main"
    Then I should be on the api page
    And I should see "USASearch APIs"

  Scenario: search.USA.gov link should be on the searchusagov page
    Given I am on the program welcome page
    When I follow "Search.USA.gov" within ".main"
    Then I should be on the searchusagov page
    And I should see "Search.USA.gov"
