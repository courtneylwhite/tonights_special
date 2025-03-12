# Tonight's Special 🍽️

## Overview

[Tonight's Special](https://trytonightsspecial.com) is a personal application designed to assist in answering the age old question of "What's for dinner".


Every day my husband wakes up at 5:30 am and by 11:00 am he is in my office coaxing me into a conversation to determine what's for dinner.
This takes some mental gymnastics on my part to parse the current groceries we have, what recipes we could make from that, if we need to do a grocery run... 
_Did I use the rest of the parmesan when I made meatballs last week? Better get some more to be safe (repeat 4 more times)_

The core features of this app will allow a user to
- CRUD a grocery
- CRUD a recipe
- Flag recipes as "made"
- See an indicator that they have all the ingredients to make a recipe
- See an indicator for each recipe ingredient that they have
- Organize groceries by custom categories
- Organize recipes by custom categories

The app should automatically
- Match ingredients in recipes to groceries the user has
- Match groceries to ingredients called for in a user's recipes

This app has one user in mind &ndash; me

I have made this repository public as a way to display my work but this is not an open source project nor is it meant to be available for public use. This is an engineering project I am creating to solve my own specific need.

## Key Features

- 🥬 Grocery Inventory Tracking
    - Currently manual entry
- 📖 Recipe Management
    - Manual entry with parsing:
        - Ingredients and Instructions are entered into 2 separate form fields
            - I wanted to be able to copy and paste my favorite recipes with minimal effort
- 🔍 Ingredient Matching
    - Ingredients are parsed using Ingreedy gem and saved
    - Ingredients are then matched to a user's current groceries using a variety of searching patterns
    - Groceries are matched to ingredients upon creation
- 🛒 Smart Grocery List Generation
    - Organized by store sections (Produce, Dairy, Meat, Pantry, etc.)
- 🍳 Recipe Feasibility Indicator
    - AvailabilityChecker checks to see if a user has no missing ingredients for a recipe
    - Stop checking after 1 missing ingredient is found
    - Shows missing and found ingredients on Recipe#Show view

## Prerequisites

- Ruby 3.4.1
- Rails 8
- Yarn
- Node.js
- PostgreSQL

## Tech Stack

- **Backend:** Ruby on Rails 8
- **Frontend:** React / TailwindCSS
- **Database:** PostgreSQL
- **Build Tools:**
    - Yarn
    - ESBuild
- **Transpilation:** Babel
- **Testing:**
    - RSpec (Backend)
    - Jest (Frontend)

## Development Tools

### Dependabot

This repository uses GitHub's Dependabot to keep dependencies up to date. Dependabot automatically creates pull requests when:
- New versions of installed packages are released
- Security vulnerabilities are discovered in existing dependencies

Pull requests include:
- Detailed changelog information
- Compatibility information
- Security advisory details (if applicable)

### Code Coverage

Code coverage is tracked using CodeCov, which provides detailed reports on test coverage across the codebase. The CodeCov badge at the top of this README shows the current coverage status for the main branch.

Coverage reports are automatically generated and uploaded to CodeCov during CI/CD pipeline execution.

## Future Planned Features

- [ ] Ingredient conversions
- [ ] View suggested recipes they can make from their current groceries
- [ ] Aggregate quantities of duplicate grocery items in grocery lists
- [ ] Organize grocery list items by section at my favorite supermarket
- [ ] Auto-clear the "made" flag after 3 days (my limit for eating leftovers)
- [ ] Deplete current pantry inventories in correlation with the quantities used in "made" recipes
- [ ] View recipes from recipe box that you are close to having all of the ingredients for
- [ ] Create grocery lists based on missing ingredients from recipes
- [ ] Grocery store receipt parsing for grocery intake
- [ ] View recipes from recipe box based on current groceries that are expiring soon
- [ ] Grocery list suggestions based on expired groceries
- [ ] Add aisle numbers to grocery items in grocery list

## Contact

As this is a personal project, contributions are not currently accepted.

**Courtney White**
- GitHub: [@courtneylwhite](https://github.com/courtneylwhite)
---

**Happy Cooking and Shopping! 👨‍🍳🛍️**
