# Creating a kachery channel

A kachery channel allows authorized kachery nodes to communicate with one another, share data, and execute tasks. To create a new channel, you must first create or claim the necessary cloud resources on [bitwooder.net](https://bitwooder.net). After that, you can configure a new kacheryhub channel to use those resources.

## Creating or claiming a Bitwooder channel resource

Each kachery channel needs to be associated with a Bitwooder resource. You can obtain one by visiting bitwooder.net and logging in with your Google ID. You can either configure your own resource by specifying Google storage bucket and Ably credentials, or you can claim one of the free available resources. Once you have claimed a new resource, click on it reveal the resource details. Copy the secret Resource Key (not the Resource ID) to your clipboard.

## Adding the channel on kacheryhub

Now that you have claimed a Bitwooder resource, you can add and configure a channel on kacheryhub. Click the button to `Create a new channel` and then paste in the Bitwooder Resource Key. Next, choose a name for your channel; you should choose a unique name without spaces. Finally, specify which nodes you would like to authorize on the channel. Be sure to select your own node as well as the Figurl node (if desired). Then click the `Add channel` button to add the channel.

IMPORTANT: After you have added the channel, restart your kachery daemon so that the changes will take effect.
