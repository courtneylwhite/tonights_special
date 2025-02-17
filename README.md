# Tonight's Special 🍽️

## Overview

Tonight's Special is a personal application designed to assist in answering the age old question of "What's for dinner". 

Every day my husband wakes up at 5:30 am and by 11:00 am he is in my office coaxing me into a conversation to determine what's for dinner.
This takes some mental gymnastics on my part to parse the current groceries we have, what recipes we could make from that, if we need to do a grocery run... 
_Did I use the rest of the parmesan when I made meatballs last week? Better get some more to be safe (repeat 4 more times)_

The core features of this app will allow a user to
- Create groceries and add them to their pantry
- Create recipes and add them to their recipe box
- View suggested recipes they can make from their current supplies
- View suggested recipes they are close to having all of the ingredients for
- Create grocery lists based on missing ingredients from recipes
- Flag recipes as "made"

The app should automatically
- Aggregate quantities of duplicate grocery items in grocery lists
- Organize grocery list items by section at my favorite supermarket
- Auto-clear the "made" flag after 3 days (my limit for eating leftovers)
- Deplete current pantry inventories in correlation with the quantities useds in "made" recipes

This app has one user in mind &ndash; me

I have made this repository public as a way to display my work but this is not an open source project nor is it meant to be available for public use. This is an engineering project I am creating to solve my own specific need.

## Key Features

- 🥬 Grocery Inventory Tracking
- 📖 Recipe Management
- 🔍 Ingredient Matching
- 🛒 Smart Grocery List Generation
    - Organized by store sections (Produce, Dairy, Meat, Pantry, etc.)
- 🍳 Recipe Feasibility Indicator

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

## Planned Features

- [ ] Ingredient conversions
- [ ] Recipe suggestions based on current pantry groceries
- [ ] Groceries suggestions based on pantry inventory and recipe cross-referencing (i.e. "You just need mozerella to make your Chicken Paremsan recipe. Do you want to add this to your grocery list?")
- [ ] Pantry inventory tracking
- [ ] Recipe categorizing
- [ ] Recipe notes
- [ ] Barcode scanning for grocery intake
- [ ] Grocery store receipt parsing for grocery intake

## Contact

As this is a personal project, contributions are not currently accepted.

**Courtney White**
- GitHub: [@courtneylwhite](https://github.com/courtneylwhite)
---

**Happy Cooking and Shopping! 👨‍🍳🛍️**
