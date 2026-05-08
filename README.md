# Supabase Lookup Variable for Google Tag Manager Server-Side

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)

A Server-Side Google Tag Manager (sGTM) variable template that allows you to fetch, track, and extract data directly from your Supabase database using the Supabase REST API.

## Features

- **Direct Database Queries:** Query any Supabase table directly from your sGTM container.
- **Query Filtering:** Apply conditions and filters using standard Supabase PostgREST syntax (e.g., `eq`, `gt`, `is`).
- **Dot Notation Extraction:** Easily extract specific nested data or array elements from the JSON response without writing custom code.
- **Smart Caching:** Built-in caching to avoid unnecessary API calls.

## How to use the Supabase Lookup Variable

1. Go to you your Google Tag Manager Server-Side container and click on **Templates** in the left sidebar. Go to the **Variables** section and click on the **"Search Gallery"** button to create a new variable. Search for **Supabase Lookup** and click on it to add it to your container.
2. Go to **Variables**, create a new User-Defined Variable, and select the **Supabase Lookup** template.
3. Configure the following fields:
   - **Project URL:** Your Supabase project URL (e.g., `https://xyz.supabase.co`).
   - **API Key:** Your Supabase `anon` or `service_role` key (depending on your required access level).
   - **Table Name:** The exact name of the table you want to query.
4. **(Optional) Add Query Conditions:** Add key-value pairs to filter the database request.
   - _Example:_ Key: `email` | Value: `eq.user@example.com`
5. **(Optional) Set Document Path:** Use dot notation to return a specific value from the API response instead of the entire JSON array.
   - _Example:_ `0.email` will extract the email address of the first record returned.
6. **(Optional) Enable Cache:** Check "Store the result in cache" and set an expiration time in minutes to prevent redundant API calls for repeated lookups.
7. Save the variable. You can now use it in your Tags, Triggers, or other Variables.

## Open Source

The **Supabase Lookup Variable for Google Tag Manager Server-Side** is developed and maintained by [Stape Team](https://stape.io/) under the Apache 2.0 license.

### GTM Gallery Status
🟢 [Listed](https://tagmanager.google.com/gallery/#/owners/stape-io/templates/supabase-lookup-variable)