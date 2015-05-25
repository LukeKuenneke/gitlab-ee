@admin
Feature: Admin license
  Background:
    Given I sign in as an admin

  Scenario: Viewing current license
    Given there is a license
    And I visit admin license page
    Then I should see to whom the license is licensed

  Scenario: Viewing license when there is none
    Given I visit admin license page
    Then I should be redirected to the license upload page

  Scenario: Viewing license history
    Given there is a license
    And there are multiple licenses
    And I visit admin license page
    Then I should see to whom the licenses were licensed

  Scenario: Uploading valid license
    Given I visit admin upload license page
    And I upload a valid license
    Then I should see a notice telling me the license was uploaded
    And I should see to whom the license is licensed

  Scenario: Uploading invalid license
    Given I visit admin upload license page
    Then I upload an invalid license
    Then I should see a warning telling me it's invalid
