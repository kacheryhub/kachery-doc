# How to Install kacheryhub and bitwooder (serverless applications)

These notes are intended for maintainers of [kacheryhub](https://www.kacheryhub.org) and
[bitwooder](https://www.bitwooder.net).

If you just want to use kachery to transfer files--including [creating your own secure channel](./channel.md)
or a [shared node for your organization](./remote-node-configuration.md)--you do not need these instructions.
These are only required for setting up the core infrastructure for a kachery network.

## Overview

The kachery network requires two centralized pieces of infrastructure:

* **kacheryhub** (the system which controls node permissions & channel membership, and handles node authentication), and
* **bitwooder** (the system which manages cloud resources and makes them available to kachery channels).

These are both implemented as '[serverless](https://en.wikipedia.org/wiki/Serverless_computing)'
systems which operate entirely on cloud infrastructure.

The system infrastructural requirements are largely the same for both systems, and consist of:

* Copies of the relevant code repository
* API keys for brief access to cloud-based computing resources (serverless functions)
* A federated identity management system/delegated authentication system ([OAuth](https://en.wikipedia.org/wiki/OAuth) provider)
* A cloud-based NoSQL/[document-oriented](https://en.wikipedia.org/wiki/Document-oriented_database) database
* For bitwooder specifically:
  * Cloud file storage resources
  * A [publish-subscribe communication bus](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) provider
* Domain names

The rest of this kachery documentation refers generically to cloud storage and computing resources rather than
specific vendors: most cloud computing providers offer interchangeable commodity offerings, and it is our intention that
the kachery system work with a wide array of cloud providers.

However, in the interest of precision, the below refers to the actual vendors used at
the time of writing, including specific URLs. Currently the code repository is hosted in [Github](https://github.com/),
most of the cloud resources are provided by the [Google Cloud Compute Platform](https://cloud.google.com/),
pub-sub communications are provided by [Ably](https://ably.com/pub-sub-messaging),
and deployments managed with [Vercel](https://vercel.com).

## Clone Repositories

Clone repositories wherever you wish to manage them:

```bash
git clone git@github.com:kacheryhub/kacheryhub.git
git clone git@github.com:kacheryhub/bitwooder.git
```

If deploying a `dev` or other non-mainline version, it may be useful to use a different name for the local
repository; this can be accomplished by adding the repository's local name as an additional parameter to
`git clone`:

```bash
git clone git@github.com:kacheryhub/kacheryhub.git dev-kacheryhub
git clone git@github.com:kacheryhub/bitwooder.git  dev-bitwooder
```

Since the remote is the same, usual git verbs will work as expected.

## Set Up Cloud Resources

### Create a new cloud platform project

* [https://console.cloud.google.com](https://console.cloud.google.com)
* Click the project selection dropdown on the left in the top bar
* Select 'New Project'
* Name it and click Create to complete workflow
* Note: To delete a project, use
[https://console.cloud.google.com/cloud-resource-manager](https://console.cloud.google.com/cloud-resource-manager)
and choose 'delete' from the kebab menu in the right-hand side of the relevant row. Technically project names
cannot be reused, but if you use a name that matches an existing project, Google will invisibly append a random
numeric string for you.

### Enable Drive API

* [https://console.cloud.google.com/apis/api/drive.googleapis.com/overview](https://console.cloud.google.com/apis/api/drive.googleapis.com/overview)
* Select the project you just created from the top-left dropdown
* Click "Enable" to enable the Drive API
* This must be completed before you can define the full scope of OAuth access

### Create an OAuth Client ID

* [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
* Ensure appropriate project is still selected
* Click "Create Credentials" near the top, below the blue bar
* Select "OAuth Client ID" from the dropdown
  * Application Type: Web Application
  * Name: e.g. `dev-kacheryhub-oauth`
  * Authorized JavaScript Origins:
    * These should include the publicly visible domain name, the Vercel pub deployment address (which you don't have yet, so may need to add later),
      and localhost.\
      So e.g.:
    * `https://dev.kacheryhub.org`
    * `https://dev-kacheryhub-USERNAME-GROUP.vercel.app`
    * `http://localhost:3000`
  * Save, and return to main credentials screen

### Configure OAuth Consent

* [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
* There may be a banner at the top; if not, click "OAuth consent screen" in the left-hand side menu.
  * Set to 'external'
  * Fill in appropriate value for user support email
  * Authorized domains: this is only the top-level domain, no protocol nor fully qualified domain name. So if
the config is for `https://dev.kacheryhub.org` just put `kacheryhub.org`.
  * Developer contact information: again, use appropriate value
* Save and continue to "Test Users"
  * Fill in the emails of the users who should have access to your test application. (This is no longer necessary after
  your application is published, but dev applications by their nature won't really be published)
* Save and continue to "Scopes"
  * Scope should include `Google Drive API .../auth/drive.file` (This will only be visible if you have already
  enabled the Drive API for the project)
* Save through to the end of the workflow, and make your way back to the main credentials screen

### Create API Key

* [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
* Again confirm the appropriate project is selected
* Again click "Create Credentials" in the top bar
* Choose "API Key"; this will immediately add a key to the list with a default name and no restrictions.
* Click the key in the list to rename/restrict it:
  * Rename the key to something memorable (e.g. `dev-kacheryhub-api-key`)
  * Under "application restrictions" click "HTTP Referrers"
  * Under "website restrictions" add entries for the publicly visible domain name, the Vercel pub deployment address, and localhost,
  with the appropriate protocol, e.g.:
    * `https://dev.kacheryhub.org`
    * `https://dev-kacheryhub-USERNAME-GROUPNAME.vercel.app`
    * `http://localhost:3000`
  * Save through to end of workflow

### Add a Service Account

* [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
* Again confirm the appropriate project is selected
* Again click "Create Credentials" in the top bar
* Select 'Service Account'; you are brought to a new workflow
  * Choose an appropriate descriptive name (e.g. `dev-kacheryhub-service-acct`)
  * Service account ID (auto-populated)
  * Service account description: an appropriate description
  * Click "Create and continue" to go to next part of workflow
  * Under "Grant this service account access to project" select the "Owner" role
    * (It is likely that more restricted roles would also work fine and be more secure--we may explore this at some point)
  * Click "Continue" to get to part 3
    * Add appropriate Flatiron/etc administrator credentials (e.g. `admin_person_email@flatironinstitute.org`)
    in the 'Service account admins role' field
  * Click "Done" and save through to the end of the workflow
  * Click the service acconut name in the table to edit it further
  * Click the "Keys" tab at the top
    * Click "Add key" dropdown and select 'Create New Key'
    * Use json key
    * **IMPORTANT**: You will be prompted to save the key credentials to your local machine. You MUST save them
    at this point. Key credentials can only be exported when the key is created; if you do not save the JSON file now, you'll
    need to create a new key.
  * Ensure the key is listed as "active" then navigate back to the main credentials window

### Add a Firestore Database

* [https://console.cloud.google.com/firestore/](https://console.cloud.google.com/firestore/)
* If this is not set up, you'll be prompted to select a mode. Choose "Native."
* Region is less important; we have been using US-East4 (Northern Virginia) but you may wish to choose something closer to your
actual intended geographic region, or choose based on pricing, etc.

### Review IAM Permissions

* [https://console.cloud.google.com/iam-admin/](https://console.cloud.google.com/iam-admin/)
* Confirm the appropriate project is shown at the upper left
* Confirm that the credentials of the appropriate administrative people, as well as the service account, are all listed
in the "Owner" role. If they aren't, add them using the "Add" button at top.
  * If you selected the "Add roles" --> "Owner" option in step 2 when creating the service account, it shouldn't need to
    be added manually here.

### Add ReCAPTCHA Support

This can probably be shared between multiple sites.

* [https://www.google.com/recaptcha/admin/](https://www.google.com/recaptcha/admin/)
* Create a new site using the + icon on the right
* Label as appropriate
* reCAPTCHA v3
* Add the sites the recaptcha key will be used for (i.e. publicly visible domain name, Vercel pub deployment address, localhost)
  * Note that unlike other UI elements in the GCP, you need to type in the domain BEFORE you hit the + icon to save it
* Ensure 'Owners' includes all appropriate people's emails
* Click to accept reCAPTCHA terms of service
* Submit, then when you're returned to the main page, ensure the correct project is selected
* Click the gear icon for settings
* You may wish to uncheck the "Verify the origin" checkbox (it is set for some, but not all, of our sites)

### Add storage resources for bitwooder

* [https://console.cloud.google.com/storage/browser](https://console.cloud.google.com/storage/browser)
  * Click "Create Bucket" (you may need to enter billing information for this to be active)
  * We default to us-east4 region, uniform access control, no access prevention, no object versioning or retention policy
* [https://ably.com/](https://ably.com/) (will take you to your own page if you are logged in; if not, log in)
  * If you have appropriate permissions, an "Add app" button should be visible on the upper right, below 'self service'
  * Click to add an app for your new installation. You'll be able to get the API key again later from the 'API Keys'
  tab in the page for this app.

## Serverless Application Deployment

### Set up project

* In a terminal window, navigate to the github repository you cloned earlier.
* Ensure that vercel is available (e.g. `which vercel`) and you're accessing the expected node.js executable
* Run `vercel` and step through the interactive setup in the terminal (you'll mostly just hit enter to accept defaults):
  * Confirm for `set up and deploy ~/LOCAL/PATH/TO/YOUR/GITHUB/REPO`
  * Confirm scope is as expected ['spikeforest' for us]
  * Fill "Project's name" as appropriate, e.g. `dev-kacheryhub`
  * Code is located at `./`
  * Auto-detected Project Settings should match those of Create React App, i.e.:
    * Build command: react-scripts build
    * Output Directory: build
    * Development Command: react-scripts start
  * Want to override the settings? N
* This workflow will create a `.vercel` config directory (which should NOT be checked in to version control) and will
give you a link to the vercel project, a URL for inspecting it, and a prod URL as a Vercel subdomain.
* NOTE: To redeploy to production later, use `vercel --prod` from this directory

### Configure Vercel project (environment variables)

* [https://vercel.com/SCOPE/PROJECTNAME/settings/](https://vercel.com/spikeforest/dev-kacheryhub/settings/)
* (Or you can navigate there from `vercel.com`)
* Under the section "Domains", attempt to register the appropriate (sub)domain to point to the Vercel servers.
  * If this isn't set up right, Vercel will give you an instruction for updating the cname; follow that.
* On the config console, sections "general", "integrations", "git", "serverless functions", "security", and "advanced"
should all be fine with defaults. (Confirm you're using Node version 14+)
* On the 'Environment Variables' tab:
  * Copy `REACT_APP_ADMIN_USERS` from an existing app, or just create a `json` list of email addresses for people who should
  be admin users.
    * Note: kacheryhub does not use the `REACT_APP_` prefix for this, not sure why
  * `REACT_APP_GOOGLE_CLIENT_ID` should get the value copied from the "OAuth 2.0 Client IDs" list in
  Google Cloud Platform ([https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials))
  * `REACT_APP_GOOGLE_API_KEY` is the dev API key from the list (click the 'multiple pages' icon to copy it)
  * `GOOGLE_CREDENTIALS` gets the complete text of the `.json` file you saved when you created the service account key. Just
  hit select-all and copy, then paste that in here.
  * `REACT_APP_RECAPTCHA_KEY` is what you get when you click "copy site key" under reCAPTCHA settings
  ([https://www.google.com/recaptcha/admin/](https://www.google.com/recaptcha/admin/))
  * `RECAPTCHA_SECRET_KEY` is what you get from 'copy secret key' on the same page
  * All these variables should be set for "Production, Preview, Deployment" (which is the default)

NOTE: Vercel does not pass environment variables through to the client-side (JavaScript) application by default.
Only variables that begin with `REACT_APP_` will be visible, so anything that needs to be used by the application
must begin with these tokens.

* Return to the terminal and re-publish (`vercel --prod`) so the new deployment picks up your environment variable
configuration.

## Test bitwooder Resource Access

* Log in to your new bitwooder site (e.g. dev.bitwooder.net)
* On the "Credentials" page, enter the Ably pub-sub resource (with its key)
* Also make an entry for the Google storage bucket (the credential here is the same `.json` file from the service
account, whose value is also used for the `GOOGLE_CREDENTIALS` environment variable)
* On the "Owned Resources" page, create a few new resources using these credentials
* Click to the individual resources and click "Make this resource claimable"
* Once they are claimable (and appear in 'Unclaimed Resources'), claim one and use it to create a new channel
on `dev.kacheryhub.org`
* Configure the new channel on the dev kacheryhub site

## Test kachery-daemon and kachery-client

* Run a kachery daemon with the `--kachery-hub-url` and `--bitwooder-url` flags set to point to the newly installed
kachery and bitwooder back-ends. Take note of the corresponding node ID.
* On the new kacheryhub site, configure the node to join the newly created channel and give it appropriate permissions
* In another terminal, use `kachery-daemon-info` to confirm that you are connecting with the appropriate daemon/node
* Attempt to load a file to the channel using `kachery-load` with the `KACHERY_HUB_API_URI` and `BITWOODER_API_URI`
environment variables set to the addresses of the newly installed sites
* Use the `--upload-to-channel` parameter to force the kachery client to interact with the bitwooder and kacheryhub resources
* A full example command line:
`KACHERY_HUB_API_URI=dev.kacheryhub.org BITWOODER_API_URI=dev.bitwooder.net kachery-store dev-channel-test.txt --upload-to-channel dev-kachery-test-channel`
* If this worked, the newly uploaded file should be visible in both the local `KACHERY_STORAGE_DIR` and via the
Google Bucket back-end at [https://console.cloud.google.com/storage/browser](https://console.cloud.google.com/storage/browser)
(you can browse through the storage through the web UI and find the file you uploaded)
