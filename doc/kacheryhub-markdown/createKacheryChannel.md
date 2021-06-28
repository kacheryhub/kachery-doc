# How to create a kachery channel

You can create a kachery channel by allocating the necessary cloud resources and then configuring your channel on kacheryhub to use those resources. A channel allows authorized kachery nodes to communicate with one another, share data, and execute tasks.

## Creating a Google storage bucket

Each channel must be associated with a Google storage bucket where cached files, feed messages, and task results are stored. It is fine for multiple channels to share the same bucket.

If you are creating the bucket yourself, follow the detailed instructions below. Otherwise, the person setting up the bucket should provide you with the name of the bucket along with secret credentials in a .json file. You will need these two pieces of information when configuring your channel on kacheryhub.

## Creating an Ably project for pub/sub communication

Each channel must be associated with an Ably project to facilitate real-time (pub/sub) communication between kachery nodes within the channel. It is fine for multiple channels to share the same Ably project.

If you are creating the Ably project yourself, follow the detailed instructions below. Otherwise, the person setting up the project should provide you with an Ably API key. You will need this key when configuring your channel on kacheryhub.

## Adding the channel on kacheryhub

Once you have set up a Google bucket and an Ably project for your channel, you can add and configure the channel on kacheryhub. Click the button to `add kachery channel` and provide a name of the channel. You should choose a unique name without spaces. Then click to configure the channel and provide the appropriate credentials for the bucket and the pub/sub project. After that, you can authorize nodes to belong to your channel with various roles.

## Google Storage Bucket creation and configuration

These are the instructions for creating and configuring a Google storage bucket for use with your channel. If somebody else created the bucket for you, you'll just need to get the name of the bucket and the secret credentials .json file from them.

1. [Create a Google Cloud Storage Bucket](https://cloud.google.com/storage/docs/creating-buckets)
2. Configure the bucket so that [all objects in the bucket are publicly readable](https://cloud.google.com/storage/docs/access-control/making-data-public#buckets).
3. Configure Cross-Origin Resource Sharing (CORS) on your bucket by creating a file named `cors.json` with the following content (where `domain-of-web-app` can be replaced by any web applications that you want to allow to access the channel data):

```json
[
    {
      "origin": ["http://localhost:3000"],
      "method": ["GET"],
      "responseHeader": ["Content-Type"],
      "maxAgeSeconds": 3600
    },
    {
      "origin": ["https://domain-of-web-app"],
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

These are the instructions for creating and configuring an Ably project for use with your channel. If somebody else created the project for you, you'll just need to get the API key from them.

1. Sign up for an account on [Ably](https://ably.com/)

2. Log in to your Ably account and create a new "App" (we'll call it a project instead of an App so it is not as confusing). The name of the project doesn't matter.

3. Create an API key for the project by clicking the "Create new API key" button. Click to enable all of the capabilities and do not specify any resource restrictions.
