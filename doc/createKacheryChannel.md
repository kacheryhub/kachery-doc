# Creating a kachery channel

A kachery channel allows authorized kachery nodes to communicate with one another, share data, and execute tasks. To create a new channel, you must first create or claim the necessary cloud resources on [bitwooder.net](https://bitwooder.net). After that, you can configure a new kacheryhub channel to use those resources.

## Creating or claiming a Bitwooder channel resource

Each kachery channel needs to be associated with a Bitwooder resource. You can obtain one by visiting bitwooder.net and logging in with your Google ID. You can either configure your own resource by specifying Google storage bucket and Ably credentials, or you can claim one of the free available resources. Once you have claimed a new resource, copy the Resource Key to your clipboard.

## Adding the channel on kacheryhub

Now that you have claimed a Bitwooder resource, you can add and configure a channel on kacheryhub. Click the button to `Create a new channel` and then paste in the Bitwooder Resource Key. Next, choose a name for your channel; you should choose a unique name without spaces. Finally, specify which nodes you would like to authorize on the channel. Be sure to select your own node as well as the Figurl node (if desired).

## Google Storage Bucket creation and configuration

These are the instructions for creating and configuring a Google storage bucket for use with a Bitwooder resource. This only applies to the case where you are creating your own Bitwooder resource.

1. [Create a Google Cloud Storage Bucket](https://cloud.google.com/storage/docs/creating-buckets)
2. Configure the bucket so that [all objects in the bucket are publicly readable](https://cloud.google.com/storage/docs/access-control/making-data-public#buckets).
3. Configure Cross-Origin Resource Sharing (CORS) on your bucket by creating a file named `cors.json` with the following content (where `domain-of-web-app` can be replaced by any web applications that you want to allow to access the channel data):

```json
[
    {
      "origin": ["*"],
      "method": ["GET"],
      "responseHeader": ["Content-Type"],
      "maxAgeSeconds": 3600
    }
]
```

and then using the [gsutil utility to set this CORS on your bucket](https://cloud.google.com/storage/docs/configuring-cors#configure-cors-bucket).

4. [Create a Google Cloud service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating) and [download credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys) to a .json file.

5. Give the service account permission to access your bucket with the "Storage Object Admin" role.

## Ably project creation and configuration

These are the instructions for creating and configuring an Ably project for use with your channel. This only applies to the case where you are creating your own Bitwooder resource.

1. Sign up for an account on [Ably](https://ably.com/)

2. Log in to your Ably account and create a new "App" (we'll call it a project instead of an App so it is not as confusing). The name of the project doesn't matter.

3. Create an API key for the project by clicking the "Create new API key" button. Click to enable all of the capabilities and do not specify any resource restrictions.
